# Exercise 1 — Portfolio Credit Risk Analysis

## Overview

This folder contains the complete analysis for Exercise 1 of the Advanzia 
Bank Risk Manager test case: an end-to-end credit risk assessment of a 
1,000-customer revolving credit card portfolio, observed monthly over a 
12-month window (October 2022 - September 2023).

The analysis is built in Python and organised into four sequential 
notebooks, each answering a specific part of the brief.

## Structure

| Notebook | Task | Contents |
|---|---|---|
| `01_data_preparation.ipynb` | Foundation | Loads the raw data, validates structure, cleans the `MonthsPastDue` column, builds all derived metrics (utilisation ratio, repayment ratio, payment compliance ratio) with documented, percentile-based outlier handling. Saves a clean dataset for the notebooks below. |
| `02_customer_behaviour.ipynb` | Task 1.1 | Describes customer behaviour and characteristics: portfolio composition, utilisation bands, Transactor/Revolver/Mixed behavioural segmentation, and time trends. |
| `03_risk_indicators.ipynb` | Task 1.2 | Computes the portfolio's key risk indicators — default rate (stock and flow), repayment ratio trends, total credit exposure, the roll rate transition matrix — and explains the observed trends, including a seasoning effect and a pre-default utilisation early-warning analysis. |
| `04_forecasting.ipynb` | Task 1.3 | Projects portfolio default rate 12 months forward using two independent, complementary methods (a Markov-chain roll-rate projection and a simple trend extrapolation), reconciles the two, and states the limitations of the forecast honestly. |

## How to read this

Each notebook follows the same pattern throughout: a short explanation of 
what is being calculated and why it matters for credit risk, followed by 
the calculation itself, followed by an interpretation of the result — and, 
where a finding is actionable, a note on what it would support doing in 
practice. All notebooks render directly on GitHub; no setup is required to 
read them. To run them, see `requirements.txt` for the Python packages used.

## Headline findings

- **Cumulative annual default rate: 10.50%** (105 of 1,000 customers 
  defaulted at least once during the year).
- **Behavioural segmentation is the strongest risk signal found**: Revolvers 
  (customers who consistently pay only the minimum) default at roughly 65 
  times the rate of Transactors (0.31% vs 20.08%), and make up just over 
  half the portfolio.
- **Utilisation is a genuine leading indicator**: customers who eventually 
  default are already running at 87% utilisation a full six months before 
  default, more than double the portfolio-wide average — visible well 
  before any formal delinquency status changes.
- **The roll rate analysis identifies a clear intervention point**: the 
  2-month-past-due stage is where most customers stop recovering and start 
  deteriorating, making it the most efficient point for collections focus.
- **Total credit exposure** to this client group stood at approximately 
  €1.32 million drawn and €2.22 million undrawn as of the end of the 
  observation window.
- **Forecast**: the portfolio's default rate is projected to rise to 
  somewhere between 18% (Markov-chain method) and 22% (trend extrapolation) 
  over the next 12 months if current behaviour continues unchanged, with 
  the lower end considered more credible given a documented deceleration in 
  new default formation through the year.

## Data

The original dataset (`Selection_process_for_Risk_Manager.xlsx`) is included 
in the `data/` subfolder, along with the cleaned, processed version produced 
by notebook 1.

## Figures

All charts referenced in the notebooks are also exported as standalone PNGs 
in the `figures/` subfolder.