# Ring the Alarm! Electricity Markets, Renewables, and the Pandemic

David Benatia. *Energy Economics* 106, 2022, article 105755.

[Published paper](https://doi.org/10.1016/j.eneco.2021.105755) · [Author manuscript](https://www.dropbox.com/scl/fi/cch7kr7oth24471dv6sb9/ring-the-alarm-author-manuscript-2021-10-25.pdf?rlkey=p1t8826akqejubhbp4ebxdz3a&dl=0) · [Author website](https://www.davidbenatia.com/research/)

MATLAB replication code for the French electricity-market application.

## Usage

1. Download the [data ZIP](https://www.dropbox.com/scl/fi/c4mlhmkok52jcnoco49sk/ring-the-alarm-data.zip?rlkey=tu5200hn261f1dz8agrmo25xe&dl=0) and extract it here, placing the eight `.mat` files beside `main.m`.
2. Run `main.m` in MATLAB.

The runner estimates counterfactual demand, emissions and generation, then the
import and supply models, and writes tables and figures under `RESULTS/`.
It uses Statistics and Machine Learning, Parallel Computing, Deep Learning,
Econometrics and Optimization toolboxes. Neural-network estimation can take time.

`extras/stata_code.do` contains supplementary IV-regression specifications using
Stata's `ivreg2`. It expects a separate `DATA_IMPREG.txt` export in the working
folder; the main MATLAB pipeline runs independently.
