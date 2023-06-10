#!/usr/bin/env bb

(require '[clojure.string :as str])

(def all-paddles (range 1 17))

(def triggers
  [{:name "ssl_trig_top_bot"
    :a [{:dsi 2 :conn 1 :ch [1 2 3 4 5 6 7 8 9 10 11 12]}
        {:dsi 3 :conn 2 :ch [5 6 7 8 9 10 11 12 13 14 15 16]}]
    :b [{:dsi 2 :conn 3 :ch [1 2 3 4 5 6 7 8 9 10 11 12]}
        {:dsi 2 :conn 4 :ch [5 6 7 8 9 10 11 12 13 14 15 16]}]}


   {:name "ssl_trig_topedge_bot"
    :a [{:dsi 2 :conn 1 :ch [13 14 15 16]}
        {:dsi 2 :conn 2 :ch [9 10 11 12]}
        {:dsi 3 :conn 5 :ch [5 6 7 8 9 10 11 12]}
        {:dsi 3 :conn 2 :ch [1 2 3 4]}
        {:dsi 3 :conn 1 :ch [5 6 7 8]}
        {:dsi 3 :conn 3 :ch [5 6 7 8 9 10 11 12]}]
    :b [{:dsi 2 :conn 3 :ch [1 2 3 4 5 6 7 8 9 10 11 12]}
        {:dsi 2 :conn 4 :ch [5 6 7 8 9 10 11 12 13 14 15 16]}]}


   {:name "ssl_trig_top_botedge"
    :a [{:dsi 2 :conn 1 :ch [1 2 3 4 5 6 7 8 9 10 11 12]}
        {:dsi 3 :conn 2 :ch [5 6 7 8 9 10 11 12 13 14 15 16]}]
    :b [{:dsi 2 :conn 2 :ch [1 2 3 4 5 6 7 8]}
        {:dsi 3 :conn 5 :ch [1 2 3 4 13 14 15 16]}
        {:dsi 3 :conn 1 :ch [9 10 11 12 13 14 15 16]}
        {:dsi 3 :conn 3 :ch [1 2 3 4 13 14 15 16]}]}


   {:name "ssl_trig_topmid_botmid"
    :a [{:dsi 2 :conn 1 :ch [1 2 3 4]}
        {:dsi 3 :conn 2 :ch [13 14 15 16]}]
    :b [{:dsi 2 :conn 3 :ch [9 10 11 12]}
        {:dsi 2 :conn 4 :ch [5 6 7 8]}]}])

(defn list-to-mask

  ([channels]
   (list-to-mask 0 channels))

  ([mask channels]
   (if (> (count channels) 0)
     (let [pos (int (Math/floor (/ (dec (first channels)) 2)))
           bit-mask (bit-shift-left 1 pos)
           bit-mask (bit-or mask bit-mask)]
       (recur bit-mask (rest channels)))
     mask)))

(defn chmap-to-string [chmap]
  (format "or_reduce(x\"%02X\" and get_hits_from_slot(hitmask, %d, %d))"
          (list-to-mask (:ch chmap)) (:dsi chmap) (:conn chmap)))

(defn trigmap-to-string [trigmap]
  (str/join " or\n          " (map #'chmap-to-string trigmap)))

(defn trig-to-vhdl [trig]
  (let [pad8 "        "
        pad6 "      "]
    (str pad6 (:name trig) " <=\n"
         pad8 "((" (trigmap-to-string  (:a trig)) ")\n"
         pad8 " and\n"
         pad8 " (" (trigmap-to-string  (:b trig)) "));\n")))

(doseq [trig (map trig-to-vhdl triggers)]
  (println trig))
