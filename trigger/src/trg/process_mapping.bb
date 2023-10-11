#!/usr/bin/env bb

;; This script is responsible for parsing the master definition spreadsheet and
;; extracting the channel mappings for the MT module.

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

(defn panel-name

  "Return a panel name given a panel number."

  [index]

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

  "Converts a field of the mapping spreadsheet from string to something more
  useful."

  [field]

  (cond

    ;; Already a number, just return it
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

    ;; Strings that can be converted to numbers
    (re-matches #"[0-9]*" field) (Integer/parseInt field)

    ;; E-X045 etc
    (re-matches #"E-X[0-9][0-9][0-9]" field) field

    ;; Fail
    :else (throw (Exception. (format  "Convert failed to process field \"%s\"" field)))))

(defn validate-headings

  "Validate the headings of the CSV file to make sure that the assigned row
  numbers match the expected headings."

  [file]

  (let [headings (first (read-csv file))]

    (letfn [(validate-heading [key re]
              (assert (re-matches re (nth headings (key columns)))
                      (format
                       "Heading #%s does not match expected format: expect \"%s\" found \"%s\""
                       (key columns)
                       re
                       (nth headings (key columns)))))]

      (validate-heading :paddle-number #"Paddle Number")
      (validate-heading :paddle-end    #"Paddle End \(A/B\)")
      (validate-heading :panel-number #"Panel Number")
      (validate-heading :rat-number #"RAT Number")
      (validate-heading :ltb-num+channel #"LTB Number-Channel")
      (validate-heading :dsi-slot #"DSI Card Slot")
      (validate-heading :ltb-harting #"LTB Harting Connection")
      (validate-heading :rb-num+channel #"RB Number-Channel")
      (validate-heading :rb-harting #"RB Harting Connection"))))

(defn csv-to-map

  "Read in a csv FILE and turn it into a map."

  [file]

  (letfn [(get-fields [row]
            (map (fn [key] (convert (nth row (key columns)))) rows))]

    ;;  strip the header from the CSV
    (->> (rest (read-csv file))

         ;; strip the NEW SECOND HEADER uhg from the spreadsheet
         rest

         ;; convert from vec to map
         (map (fn [row] (apply hash-map (interleave rows (get-fields row)))))

         ;; add the station number in
         (map (fn [x] (assoc x :station (panel-name (:panel-number x))))))))

(defn bounds-check [val min max name map]
  (assert (<= min val max)
          (format "%s %d out of range (%d to %d) in %s" name val min max map)))

(defn get-global-ltb-index

  "Return the global enumerated bit index for a given LTB channel.

  There are 8 channels per harting connector, 5 hartings per DSI."

  [data-map]

  (+ (int (/ (dec (:ch (:ltb-num+channel data-map))) 2)) ; transform 1-16 --> 0-7
     (* 8 (:ltb-harting data-map))
     (* 8 5 (dec (:dsi-slot data-map)))))

(defn get-global-rb-index

  "Return the global enumerated bit index for a given RB channel.

  There are 16 channels per harting connector, 5 hartings per DSI.

  Each harting connector corresponds to two different RBs (8 channels each)."

  [data-map]

  (let [ch (dec (:ch (:rb-num+channel data-map)))    ; channel within the RB; 0-7
        half (if  (= :B (:paddle-end data-map)) 1 0) ; which 1/2 of the harting connector?
        harting (:rb-harting data-map)               ; which harting connector?
        dsi (dec (:dsi-slot data-map))               ; which DSI?
        index (+ ch
                 (* 8  half)            ; 8 RB channels per harting split half
                 (* 16 harting)         ; 16 RB channels per harting
                 (* 16 5 dsi))]         ; 80 RB channels per DSI

    (assert (or  (= :A (:paddle-end data-map))
                 (= :B (:paddle-end data-map))))
    (bounds-check ch 0 7 "RB Channel" data-map)
    (bounds-check half 0 8 "RB Half A/B" data-map)
    (bounds-check harting 0 5 "RB Harting" data-map)
    (bounds-check dsi 0 5 "DSI" data-map)
    (bounds-check index 0 399 "RB Index" data-map)

    index))

(defn format-ltb-map

  "Format a single instance of an LTB data map and return a VHDL bit assignment string."

  [ltb cnt]

  ;; error checking
  (bounds-check (:dsi-slot ltb) 1 5 "Dsi Slot" ltb)
  (bounds-check (:ch (:ltb-num+channel ltb)) 1 16 "LTB Channel" ltb)
  (bounds-check (get-global-ltb-index ltb) 0 199 "LTB Index" ltb)

  ;; formatting
  (format "    %s(%2d) <= hits_i(%3d); -- panel=%2s paddle=%3s station=%s; LTB DSI%s J%s Ch%2s Bit%s"
          (:station ltb)
          cnt
          (get-global-ltb-index ltb)
          (:panel-number ltb)
          (:paddle-number ltb)
          (:station ltb)
          (:dsi-slot ltb)
          (inc (:ltb-harting ltb))
          (:ch (:ltb-num+channel ltb))
          (int (/ (dec (:ch (:ltb-num+channel ltb))) 2))))


(defn format-rb-map

  "Format a single instance of an RB data map and return a VHDL bit assignment string."

  [rb-map]

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


(validate-headings "mapping.csv")

(let [data-map (csv-to-map "mapping.csv")]

  (when (:map-ltb args)
    (doseq [station [ "cube" "umbrella" "cube_bot" "cube_corner" "cortina"]]
      (let [paddles (->> data-map
                         (remove #(= :B (:paddle-end %)))
                         (filter #(= (:station %) station)))]
        (doseq [ltbmap (map vector  paddles (range (count paddles)))]
          (println (format-ltb-map (first ltbmap) (last ltbmap))))
        (println ""))))

  (when (:map-rb args)
    ;; sort the datamap by the ltb number to put it in some order
    (let [datamap (sort-by 'get-global-ltb-index data-map)]
      (doseq [rbmap datamap]
        (println (format-rb-map rbmap))))))
