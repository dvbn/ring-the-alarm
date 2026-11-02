# Ring the Alarm! Electricity Markets, Renewables, and the Pandemic

David Benatia. *Energy Economics* 106, 2022, article 105755.

[Published paper](https://doi.org/10.1016/j.eneco.2021.105755) · [Author manuscript](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3703117) · [Author website](https://www.davidbenatia.com/research/)

MATLAB replication code for the French electricity-market application.

## Usage

1. Extract the accompanying data ZIP into this folder, placing the eight `.mat` files beside `main.m`.
2. Run `main.m` in MATLAB.

The runner estimates counterfactual demand, emissions and generation, then the
import and supply models, and writes tables and figures under `RESULTS/`.
It uses Statistics and Machine Learning, Parallel Computing, Deep Learning,
Econometrics and Optimization toolboxes. Neural-network estimation can take time.

`extras/stata_code.do` contains supplementary IV-regression specifications using
Stata's `ivreg2`. It expects a separate `DATA_IMPREG.txt` export in the working
folder; the main MATLAB pipeline runs independently.
