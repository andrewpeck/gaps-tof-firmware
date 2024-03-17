#!/usr/bin/env bb

;; This script is responsible for parsing the master definition spreadsheet and
;; extracting the channel mappings for the MT module.

(require '[clojure.string :as str])
(require '[clojure.java.io :as io])
(require '[cheshire.core :as json])
(require '[babashka.cli :as cli])

(defn get-channel [number-channel]
  (dec (Integer/parseInt (last (str/split number-channel #"[-]")))))

(defn get-number [number-channel]
  (dec (Integer/parseInt (first (str/split number-channel #"[-]")))))

(defn get-harting [JX]
  ;; Things of the form J3, extract as J3 -> 2 so that we count from zero
  (dec (Integer/parseInt (subs JX 1))))

(defn get-panel-type [x]
  (-> x
      (clojure.string/replace ,,, #" " "_")
      (clojure.string/replace ,,, "cube_side" "cube")
      (clojure.string/replace ,,, "cube_bottom" "cube_bot")
      (clojure.string/replace ,,, "corner" "cube_corner")
      ))

(defn get-global-ltb-index

  "Return the global enumerated bit index for a given LTB channel.

  There are 8 channels per harting connector, 5 hartings per DSI."

  [data-map]

  (+ (int (/ (get-channel (:ltb_number_channel data-map)) 2)) ; transform 1-16 --> 0-7
     (* 8 (get-harting (:ltb_harting_connection data-map)))
     (* 8 5 (dec (:dsi_card_slot data-map)))))

(defn get-global-rb-index

  "Return the global enumerated bit index for a given RB channel.

  There are 16 channels per harting connector, 5 hartings per DSI.

  Each harting connector corresponds to two different RBs (8 channels each)."

  [data-map]

  (try (let [ch (get-channel (:rb_number_channel data-map)) ; channel within the RB; 0-7
             half (if  (= "B" (:rb_harting_connection_split data-map)) 0 1) ; which 1/2 of the harting connector?
             harting (get-harting (:rb_harting_connection data-map)) ; which harting connector?
             dsi (dec (:dsi_card_slot data-map)) ; which DSI?
             index (+ ch
                      (* 8  half)       ; 8 RB channels per harting split half
                      (* 16 harting)    ; 16 RB channels per harting
                      (* 16 5 dsi))]    ; 80 RB channels per DSI

         (assert (or  (= "A" (:paddle_end data-map))
                      (= "B" (:paddle_end data-map))))

         index)
       ;; java.lang.NullPointerException
       (catch Exception e (str "caught exception: " (.getMessage e)) -1)))

(defn format-ltb-map

  "Format a single instance of an LTB data map and return a VHDL bit assignment string."

  [ltb cnt]

  ;; formatting
  (format "    %s(%2d) <= hits_i(%3d); -- panel=%2s paddle=%3s station=%s; LTB DSI%s J%s Ch%2s Bit%s"
          (get-panel-type (:panel_type ltb))
          cnt
          (get-global-ltb-index ltb)
          (:panel_number ltb)
          (:paddle_number ltb)
          (:panel_type ltb)
          (:dsi_card_slot ltb)
          (inc (get-harting (:ltb_harting_connection ltb)))
          (get-channel (:ltb_number_channel ltb))
          (int (/ (get-channel (:ltb_number_channel ltb)) 2))))


(defn format-rb-map

  "Format a single instance of an RB data map and return a VHDL bit assignment string."

  [rb-map short-circuits]

  (let [rb-idx (get-global-rb-index rb-map)
        ltb-idx (get-global-ltb-index rb-map)
        is-dup (if  (some #{rb-idx} short-circuits) " [Short Circuit]" "")]

    (format "  rb_ch_bitmap_o(%3d) <= hits_bitmap_i(%3d); -- %s <- %s ::: %s%s"
            rb-idx
            ltb-idx
            (format "rb %s" (:rb_number_channel rb-map))
            (format "ltb %s" (:ltb_number_channel rb-map))
            rb-map
            is-dup)))

;;------------------------------------------------------------------------------
;; Runtime
;;------------------------------------------------------------------------------

(defn dups [seq]
  (for [[id freq] (frequencies seq)  ;; get the frequencies, destructure
        :when (> freq 1)] id)) ;; this is the filter condition

(def args
  (cli/parse-opts *command-line-args*
                  {:coerce {:map-rb :boolean :map-ltb :boolean}}))

(let [data-map (json/parse-stream (io/reader "mapping-validated.json") true)]

  (when (:map-ltb args)
    (doseq [station [ "cube" "umbrella" "cube side" "cube top" "cube bottom" "corner" "cortina"]]
      (let [paddles (->> data-map
                         (remove #(= "B" (:paddle_end %)))
                         (filter #(= (:panel_type %) station)))]
        (doseq [ltbmap (map vector  paddles (range (count paddles)))]
          (println (format-ltb-map (first ltbmap) (last ltbmap))))
        (println ""))))

  (when (:map-rb args)

  ;; sort the datamap by the ltb number to put it in some order
  (let [data-sorted (sort-by (fn [x] (get-global-ltb-index x)) data-map)
        rb-indexes (mapv get-global-rb-index data-sorted)
        short-circuits (dups rb-indexes)]
    (doseq [rb-ltb data-sorted]
      (println (format-rb-map rb-ltb short-circuits))))))
