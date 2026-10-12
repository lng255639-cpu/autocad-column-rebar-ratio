;;; ============================================================
;;; COLRHO_EN.lsp  Column reinforcement ratio calculator
;;; Load:    APPLOAD, or drag this file into the AutoCAD window
;;; Command: COLRHO
;;; Rebar input formats:  8-#8   8#8   8-D25   12-#10+4-#8
;;; Ratio rho_g = Ast / Ag (gross section), units in cm
;;; ============================================================

(vl-load-com)

;; Bar size . nominal area (cm2), per CNS 560
(setq *colrho-bars*
  '((3 . 0.7133) (4 . 1.267) (5 . 1.986) (6 . 2.865) (7 . 3.871)
    (8 . 5.067) (9 . 6.469) (10 . 8.143) (11 . 10.07) (14 . 14.52) (18 . 25.79)))

;; D designation . bar size
(setq *colrho-dmap*
  '((10 . 3) (13 . 4) (16 . 5) (19 . 6) (22 . 7) (25 . 8)
    (29 . 9) (32 . 10) (36 . 11) (43 . 14) (57 . 18)))

;; Split a string by a delimiter
(defun colrho:split (str delim / pos lst)
  (while (setq pos (vl-string-search delim str))
    (setq lst (cons (substr str 1 pos) lst)
          str (substr str (+ pos 1 (strlen delim)))))
  (reverse (cons str lst)))

;; "8-#8" -> (8 8 5.067); returns nil on bad format
(defun colrho:term (s / pos mk n sz a)
  (cond ((setq pos (vl-string-search "#" s)) (setq mk "#"))
        ((setq pos (vl-string-search "D" s)) (setq mk "D")))
  (if pos
    (progn
      (setq n  (atoi (vl-string-right-trim "-X*@" (substr s 1 pos)))
            sz (atoi (substr s (+ pos 2))))
      (if (= mk "D") (setq sz (cdr (assoc sz *colrho-dmap*))))
      (if (and sz (> n 0) (setq a (cdr (assoc sz *colrho-bars*))))
        (list n sz a)))))

;; Full rebar string -> ((count size bar-area) ...); nil if any part is invalid
(defun colrho:parse (str / lst item ok)
  (setq str (strcase str))
  (while (vl-string-search " " str)
    (setq str (vl-string-subst "" " " str)))
  (setq ok T)
  (foreach s (colrho:split str "+")
    (if (setq item (colrho:term s))
      (setq lst (cons item lst))
      (setq ok nil)))
  (if (and ok lst) (reverse lst)))

(defun c:COLRHO (/ shp b h d ag str bars as rho desc bdesc chk txt pt)
  (if (not *colrho-shp*) (setq *colrho-shp* "R"))
  (if (not *colrho-b*)   (setq *colrho-b* 60.0))
  (if (not *colrho-h*)   (setq *colrho-h* 60.0))
  (if (not *colrho-d*)   (setq *colrho-d* 60.0))
  (if (not *colrho-str*) (setq *colrho-str* "8-#8"))

  ;; Section shape
  (initget "R C")
  (setq shp (getkword (strcat "\nColumn section R=Rectangular / C=Circular <" *colrho-shp* ">: ")))
  (if shp (setq *colrho-shp* shp) (setq shp *colrho-shp*))

  ;; Section dimensions
  (if (= shp "R")
    (progn
      (initget 6)
      (setq b (getreal (strcat "\nWidth b (cm) <" (rtos *colrho-b* 2 1) ">: ")))
      (if b (setq *colrho-b* b) (setq b *colrho-b*))
      (initget 6)
      (setq h (getreal (strcat "\nDepth h (cm) <" (rtos *colrho-h* 2 1) ">: ")))
      (if h (setq *colrho-h* h) (setq h *colrho-h*))
      (setq ag   (* b h)
            desc (strcat (rtos b 2 1) "x" (rtos h 2 1) "cm")))
    (progn
      (initget 6)
      (setq d (getreal (strcat "\nDiameter D (cm) <" (rtos *colrho-d* 2 1) ">: ")))
      (if d (setq *colrho-d* d) (setq d *colrho-d*))
      (setq ag   (/ (* pi d d) 4.0)
            desc (strcat "D=" (rtos d 2 1) "cm"))))

  ;; Reinforcement
  (while (not bars)
    (setq str (getstring T (strcat "\nRebar (e.g. 8-#8 or 12-#10+4-#8) <" *colrho-str* ">: ")))
    (if (= str "") (setq str *colrho-str*))
    (if (setq bars (colrho:parse str))
      (setq *colrho-str* str)
      (princ "\n** Invalid format, try again (e.g. 8-#8, 8#8, 8-D25, 12-#10+4-#8) **")))

  ;; Calculation
  (setq as 0.0 bdesc "")
  (foreach x bars
    (setq as    (+ as (* (car x) (caddr x)))
          bdesc (strcat bdesc (if (= bdesc "") "" " + ")
                        (itoa (car x)) "-#" (itoa (cadr x)))))
  (setq rho (* 100.0 (/ as ag)))
  (setq chk
    (cond ((< rho 1.0) "NG  below minimum ratio 1%")
          ((> rho 8.0) "NG  above maximum ratio 8%")
          ((> rho 4.0) "OK  (but > 4%, congestion likely at lap splices)")
          (T           "OK  (1% <= rho_g <= 8%)")))

  ;; Output
  (setq txt (strcat
    "Section: " desc "\n"
    "Ag    = " (rtos ag 2 2) " cm2\n"
    "Rebar: " bdesc "\n"
    "As    = " (rtos as 2 2) " cm2\n"
    "rho_g = " (rtos rho 2 3) " %\n"
    "Check: " chk))
  (princ (strcat "\n====== Column Reinforcement Ratio ======\n" txt
                 "\n========================================"))
  (alert txt)

  ;; Write result into the drawing (optional)
  (setq pt (getpoint "\nPick point to place result text <Enter to skip>: "))
  (if pt
    (entmake
      (list '(0 . "MTEXT") '(100 . "AcDbEntity") '(100 . "AcDbMText")
            (cons 10 (trans pt 1 0))
            (cons 40 (getvar "TEXTSIZE"))
            (cons 7 (getvar "TEXTSTYLE"))
            (cons 1 (strcat "COL " desc "\\P"
                            bdesc "  As=" (rtos as 2 2) "cm2\\P"
                            "Rho=" (rtos rho 2 2) "%")))))
  (princ))

(princ "\nCOLRHO loaded. Type COLRHO to run.")
(princ)
