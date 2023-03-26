(require '[clojure.java.shell :refer [sh]]
         ;; '[cheshire.core :as json]
         '[clojure.string :as str])
;; ;; (println  (json/generate-string triggers {:pretty true}))

(def all-paddles
  (range 1 17))

(def triggers
  [{:name "ssl_trig_top_bot"
    :a [{:dsi 1 :conn 1 :ch all-paddles}
        {:dsi 2 :conn 2 :ch all-paddles}]
    :b [{:dsi 1 :conn 3 :ch all-paddles}
        {:dsi 1 :conn 5 :ch all-paddles}]}

   {:name "ssl_trig_topedge_bot"
    :a [{:dsi 1 :conn 3 :ch [2 1 4 3 6 5 8 7 10 9 12 11]}
        {:dsi 1 :conn 5 :ch [5 6 7 8 9 10 11 12 13 14 15 16]}]
    :b [{:dsi 1 :conn 1 :ch [14 13 16 15]}
        {:dsi 1 :conn 2 :ch [12 11 10 9]}
        {:dsi 1 :conn 4 :ch [10 9 8 7 12 11 6 5]}
        {:dsi 2 :conn 2 :ch [1 2 3 4]}
        {:dsi 2 :conn 1 :ch [5 6 7 8]}
        {:dsi 2 :conn 3 :ch [10 9 8 7 12 11 6 5]}]}])

(defn list-to-mask

  ([channels]
   (list-to-mask 0 channels))

  ([mask channels]
   (if (> (count channels) 0)
     (recur (bit-or mask (bit-shift-left 1 (int (Math/floor (/ (dec (first channels)) 2)))))
            (rest channels)) mask)))

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
