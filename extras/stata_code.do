clear
import delimited "DATA_IMPREG.txt", encoding(ISO-8859-1) clear

gen time2 = _n

tsset time2

ivreg2 echphysiques temp_fr_paris temp_it_turin temp_de_frankfurt temp_es_barcelona temp_ch_geneva temp_uk_london temp_be_brussels solar_be windoffshore_be windonshore_be solar_ch windonshore_ch solar_de windoffshore_de windonshore_de solar_es windonshore_es solar_fr solar_uk windoffshore_uk windonshore_uk ch_fr fr_ch es_fr fr_es it_fr fr_it uk_fr fr_uk mon tue wed thu fri sat hour1 hour2 hour3 hour4 hour5 hour6 hour7 hour8 hour9 hour10 hour11 hour12 hour13 hour14 hour15 hour16 hour17 hour18 hour19 hour20 hour21 hour22 hour23 feb mar apr may jun jul aug sep oct nov dec v79 v80 timetrend newyear xmas xmaseve newyeareve armistice bastille marie toussaint paques travail ascension pentecote musique victoire (price_fr = windonshore_fr), gmm2s  robust

ivreg2 echphysiques temp_fr_paris temp_it_turin temp_de_frankfurt temp_es_barcelona temp_ch_geneva temp_uk_london temp_be_brussels solar_be windoffshore_be windonshore_be solar_ch windonshore_ch solar_de windoffshore_de windonshore_de solar_es windonshore_es solar_fr solar_uk windoffshore_uk windonshore_uk ch_fr fr_ch es_fr fr_es it_fr fr_it uk_fr fr_uk mon tue wed thu fri sat hour1 hour2 hour3 hour4 hour5 hour6 hour7 hour8 hour9 hour10 hour11 hour12 hour13 hour14 hour15 hour16 hour17 hour18 hour19 hour20 hour21 hour22 hour23 feb mar apr may jun jul aug sep oct nov dec v79 v80 timetrend newyear xmas xmaseve newyeareve armistice bastille marie toussaint paques travail ascension pentecote musique victoire (price_fr = windonshore_fr), gmm2s  bw(12) kernel(bartlett)

*ivreg2 echphysiques temp_fr_paris temp_it_turin temp_de_frankfurt temp_es_barcelona temp_ch_geneva temp_uk_london temp_be_brussels solar_be windoffshore_be windonshore_be solar_ch windonshore_ch solar_de windoffshore_de windonshore_de solar_es windonshore_es solar_fr solar_uk windoffshore_uk windonshore_uk ch_fr fr_ch es_fr fr_es it_fr fr_it uk_fr fr_uk mon tue wed thu fri sat hour1 hour2 hour3 hour4 hour5 hour6 hour7 hour8 hour9 hour10 hour11 hour12 hour13 hour14 hour15 hour16 hour17 hour18 hour19 hour20 hour21 hour22 hour23 feb mar apr may jun jul aug sep oct nov dec v79 v80 timetrend newyear xmas xmaseve newyeareve armistice bastille marie toussaint paques travail ascension pentecote musique victoire (price_fr = eolien), gmm2s  bw(12) kernel(bartlett)



ivreg2 price_fr naturalgas_price temp_fr_paris temp_it_turin temp_de_frankfurt temp_es_barcelona temp_ch_geneva temp_uk_london temp_be_brussels solar_be windoffshore_be windonshore_be solar_ch windonshore_ch solar_de windoffshore_de windonshore_de solar_es windonshore_es solar_fr solar_uk windoffshore_uk windonshore_uk ch_fr fr_ch es_fr fr_es it_fr fr_it uk_fr fr_uk mon tue wed thu fri sat hour1 hour2 hour3 hour4 hour5 hour6 hour7 hour8 hour9 hour10 hour11 hour12 hour13 hour14 hour15 hour16 hour17 hour18 hour19 hour20 hour21 hour22 hour23 feb mar apr may jun jul aug sep oct nov dec v79 v80 timetrend newyear xmas xmaseve newyeareve armistice bastille marie toussaint paques travail ascension pentecote musique victoire (q nucleaire = windonshore_fr nuke_ucap_f), gmm2s  robust

ivreg2 price_fr naturalgas_price temp_fr_paris temp_it_turin temp_de_frankfurt temp_es_barcelona temp_ch_geneva temp_uk_london temp_be_brussels solar_be windoffshore_be windonshore_be solar_ch windonshore_ch solar_de windoffshore_de windonshore_de solar_es windonshore_es solar_fr solar_uk windoffshore_uk windonshore_uk ch_fr fr_ch es_fr fr_es it_fr fr_it uk_fr fr_uk mon tue wed thu fri sat hour1 hour2 hour3 hour4 hour5 hour6 hour7 hour8 hour9 hour10 hour11 hour12 hour13 hour14 hour15 hour16 hour17 hour18 hour19 hour20 hour21 hour22 hour23 feb mar apr may jun jul aug sep oct nov dec v79 v80 timetrend newyear xmas xmaseve newyeareve armistice bastille marie toussaint paques travail ascension pentecote musique victoire (q nucleaire = windonshore_fr nuke_ucap_f), gmm2s  robust
ivreg2 price_fr naturalgas_price temp_fr_paris temp_it_turin temp_de_frankfurt temp_es_barcelona temp_ch_geneva temp_uk_london temp_be_brussels solar_be windoffshore_be windonshore_be solar_ch windonshore_ch solar_de windoffshore_de windonshore_de solar_es windonshore_es solar_fr solar_uk windoffshore_uk windonshore_uk ch_fr fr_ch es_fr fr_es it_fr fr_it uk_fr fr_uk mon tue wed thu fri sat hour1 hour2 hour3 hour4 hour5 hour6 hour7 hour8 hour9 hour10 hour11 hour12 hour13 hour14 hour15 hour16 hour17 hour18 hour19 hour20 hour21 hour22 hour23 feb mar apr may jun jul aug sep oct nov dec v79 v80 timetrend newyear xmas xmaseve newyeareve armistice bastille marie toussaint paques travail ascension pentecote musique victoire (q nucleaire = windonshore_fr nuke_ucap_f), gmm2s  bw(12) kernel(bartlett)





