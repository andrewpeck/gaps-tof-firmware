#!/usr/bin/env bb

(require '[clojure.string :as str])
(require '[clojure.data.csv :as csv])
(require '[clojure.java.io :as io])
(require '[babashka.cli :as cli])

(defn read-csv [file]
  (with-open [reader (io/reader file)]
    (doall (csv/read-csv reader))))

(def columns {:paddle-number 0   ;; A Paddle Number
              :paddle-end 1      ;; B Paddle End
              :panel-number 3    ;; D Panel Number
              :rat-number 7      ;; H Rat Number
              :ltb-num+channel 8 ;; I LTB Number-Channel
              :dsi-slot 10       ;; K DSI Card Slot
              :ltb-harting 11    ;; L LTB Harting Connection
              :rb-num+channel 9  ;; J RB Number-Channel
              :rb-harting 12})   ;; M RB Harting Connection

(def rows (keys columns))

(defn panel-name [index]

  (if (number? index)

    ;; Convert numerical indexes
    (cond (= index :N/A) "cube_corner"

          (= index 2) "cube_bot"

          (and (>= index 1)
               (<= index 6)) "cube"

          (and (>= index 7)
               (<= index 13)) "umbrella"

          (and (>= index 14)
               (<= index 21)) "cortina"

          :else (throw (Exception. (format "Invalid numerical panel index specified %s" index))))

    ;; Convert string indexes
    (cond
      (re-matches #"E-X[0-9][0-9][0-9]" index) "cube_corner"
      :else (throw (Exception. (format "Invalid string panel index specified %s" index))))))

(defn convert

  "Converts a field of the mapping spreadsheet from string to something more useful."

  [field]

  (cond

    (number? field) field

    ;; Not available
    (= field "") :N/A

    ;; Things of the form A or B
    (re-matches #"[AB]" field) (keyword field)

    ;; Things of the form 03-12
    (re-matches #"[0-9]+-[0-9]+" field)
    ((fn [x] {:board (convert (first x))
              :ch (convert (last x))})
     (str/split field #"[-]"))

    ;; Things of the form J3, extract as J3 -> 3 -> 2 so that we count from zero
    (re-matches #"J[0-9]" field) (dec (Integer/parseInt (apply str (rest field))))

    ;; Numbers
    :else (try (Integer/parseInt field)
               (catch NumberFormatException _ (format  "Error parsing int!! %s" field) field))))

(defn read-mapping-csv [file]

  (letfn [(get-fields [row]
            (map (fn [key] (convert (nth row (key columns)))) rows))]

    ;;  strip the header from the CSV
    (->> (rest (read-csv file))

         ;; strip the NEW SECOND HEADER uhg from the spreadsheet
         rest

         ;; convert from vec to map
         (map (fn [row] (apply hash-map (interleave rows (get-fields row)))))

         ;; remove the B ends of the paddle; they are not needed for our purposes
         ;; since they are ORed in the LTB
         (remove #(= :B (:paddle-end %)))

         ;; add the station number in
         (map (fn [x] (assoc x :station (panel-name (:panel-number x))))))))

(defn format-ltb-map [ltb cnt]
  (format "    %s(%2d) <= hits_i(%3d); -- panel=%s paddle=%s station=%s; LTB DSI%s J%s CH%s"
          (:station ltb)
          cnt
          (+  (dec (:ch (:ltb-num+channel ltb)))
              (* 8 (:ltb-harting ltb))
              (* 8 5 (:dsi-slot ltb)))
          (:panel-number ltb)
          (:paddle-number ltb)
          (:station ltb)
          (:dsi-slot ltb)
          (inc (:ltb-harting ltb))
          (:ch (:ltb-num+channel ltb))))

(defn get-global-ltb-index [data-map]
  (+ (dec (:ch (:ltb-num+channel data-map)))
     (* 8 (:ltb-harting data-map))
     (* 8 5 (:dsi-slot data-map))))

(defn get-global-rb-index [data-map]
  (+ (dec (:ch (:rb-num+channel data-map))) ; channel within the RB; 0-7
     0                                      ; FIXME: which 1/2 of the harting connector?
     (* 16 (:rb-harting data-map))          ; which harting connector?
     (* 16 5 (:dsi-slot data-map))))        ; which DSI?

(defn format-rb-map [rb-map]

  (if (= :N/A (:rb-num+channel rb-map))

    ;; Emit a warning comment for N/A mappings
    (format "-- Failed to map                             -- %s" rb-map)

    (format "  rb_ch_bitmap_o(%3d) <= hits_bitmap_i(%3d); -- %s"
            (get-global-rb-index rb-map)
            (get-global-ltb-index rb-map)
            rb-map)))

;;------------------------------------------------------------------------------
;; Runtime
;;------------------------------------------------------------------------------

(def args
  (cli/parse-opts *command-line-args*
                  {:coerce {:map-rb :boolean :map-ltb :boolean}}))

(let [data-map (read-mapping-csv "mapping.csv")]

  (when (:map-ltb args)
    (doseq [station [ "cube" "umbrella" "cube_bot" "cube_corner" "cortina"]]
      (let [paddles (filter #(= (:station %) station) data-map)]
        (doseq [ltbmap (map vector  paddles (range (count paddles)))]
          (println (format-ltb-map (first ltbmap) (last ltbmap))))
        (println ""))))

  (when (:map-rb args)
    ;; sort the datamap by the ltb number to put it in some order
    (let [datamap (sort-by 'get-global-ltb-index data-map)]
      (doseq [rbmap datamap]
        (println (format-rb-map rbmap))))))
