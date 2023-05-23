#!/usr/bin/env bb

(require '[clojure.string :as str])
(require '[clojure.data.csv :as csv])
(require '[clojure.java.io :as io])
(require '[babashka.cli :as cli])

(defn read-csv [file]
  (with-open [reader (io/reader file)]
    (doall (csv/read-csv reader))))

(def columns {:paddle-number 0
              :paddle-end 2
              :panel-number 4
              :rat-number 8
              :ltb+channel 9
              :ltb-harting 10
              :rb+channel 11
              :rb-harting 12})

(def rows (keys columns))

(defn panel-name [index]

  (cond (= index :N/A) "cube_corner"

        (= index 2) "cube_bot"

        (and (>= index 1)
             (<= index 6)) "cube"

        (and (>= index 7)
             (<= index 13)) "umbrella"

        (and (>= index 14)
             (<= index 21)) "cortina"

        :else (throw (Exception. (format "Invalid panel index specified %s" index)))))

(defn convert
  "Converts a field of the mapping spreadsheet from string to something more useful."
  [field]

  (cond

    (number? field) field

    ;; Not available
    (= field "") :N/A
    ;;
    ;; Things of the form A or B
    (re-matches #"[AB]" field) (keyword field)

    ;; Things of the form 03-12
    (re-matches #"[0-9]+-[0-9]+" field)
    ((fn [x] {:board (convert (first x))
              :ch (convert (last x))})
     (str/split field #"[-]"))

    ;; Numbers
    :else (try (Integer/parseInt field)
               (catch NumberFormatException _ (format  "Error parsing int!! %s" field)))))

(defn read-mapping-csv [file]

  (letfn [(get-fields [row]
            (map (fn [key] (convert (nth row (key columns)))) rows))]

    ;;  strip the header from the CSV
    (->> (rest (read-csv file))

         ;; convert from vec to map
         (map (fn [row] (apply hash-map (interleave rows (get-fields row)))))

         ;; remove the B ends of the paddle; they are not needed for our purposes
         ;; since they are ORed in the LTB
         (remove #(= :B (:paddle-end %)))

         ;; add the station number in
         (map (fn [x] (assoc x :station (panel-name (:panel-number x))))))))

(defn format-ltb-map [ltb cnt]
  (format "    %s(%d) <= hits_i(%d); -- panel=%s paddle=%s station=%s"
          (:station ltb)
          cnt
          (dec (:paddle-number ltb)) ;; (dec (:channel (:ltb-harting ltb))) ; FIXME: update when map is done
          (:panel-number ltb)
          (:paddle-number ltb)
          (:station ltb)))

(defn format-rb-map [rb-map]

  (letfn [(get-ch    [key] (dec (:ch (key rb-map))))
          (get-board [key] (dec (:board (key rb-map))))]

    ;; FIXME: this should be replaced with ltb+harting when it is available
    (let [rb  (get-board :rb+channel)
          rb-ch (get-ch :rb+channel)

          ltb  (get-board :ltb+channel)
          ltb-ch (get-ch :ltb+channel)

          ltb-enum (+ ltb-ch  (* 8 ltb ))
          rb-enum (+ rb-ch  (* 8 rb ))]

      (format "  rb_ch_bitmap_o(%3d) <= hits_bitmap_i(%d); -- rb=%s lrb=%s"
              rb-enum
              ltb-enum
              (:rb+channel rb-map)
              (:ltb+channel rb-map)))))

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
    (let [datamap (sort-by
                   ;; FIXME: this should be replaced with ltb+harting when it is available
                   (fn [x] (+ (* 8 (dec (:board  (:ltb+channel x))))
                              (dec (:ch  (:ltb+channel x))))) data-map)]
      (doseq [rbmap datamap]
        (println (format-rb-map rbmap))))))
