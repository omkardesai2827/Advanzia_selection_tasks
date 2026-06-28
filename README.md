# Advanzia Bank S.A. — Risk Manager Test Case

## Overview

This repository contains my completed submission for the Advanzia Bank 
Risk Manager test case, covering both exercises set out in the selection 
procedure: a portfolio credit risk analysis (Python) and a model 
validation review (R).

## Repository structure

```
Advanzia_selection_tasks/
├── README.md                       
│
├── exercise1_portfolio_analysis/
│   ├── README.md
│   ├── 01_data_preparation.ipynb
│   ├── 02_customer_behaviour.ipynb
│   ├── 03_risk_indicators.ipynb
│   ├── 04_forecasting.ipynb
│   ├── exercise1_summary.md
│   ├── data/
│   └── figures/
│
└── exercise2_model_validation/
    ├── original_code.R
    ├── corrected_code.R
    ├── model_validation_review.Rmd
    ├── model_validation_review.html
    └── exercise2_summary.md
```

## Exercise 1 — Portfolio Credit Risk Analysis

An end-to-end credit risk assessment of a 1,000-customer revolving credit 
card portfolio, observed monthly over a 12-month window. Built in Python 
across four sequential notebooks: data preparation, customer behaviour 
description, risk indicator calculation, and a 12-month forecast.

Headline finding: customers who eventually default are already running at 
87% credit utilisation a full six months before default occurs more than 
double the portfolio average — making sustained high utilisation a genuine, 
actionable early warning signal.

Full details, including all headline findings, are in 
[`exercise1_portfolio_analysis/exercise1_summary.md`](exercise1_portfolio_analysis/exercise1_summary.md).

## Exercise 2 — Model Validation Review

A line-by-line review of the R code provided for a behavioural credit 
scorecard, identifying coding and logical errors, methodology and 
performance assessment gaps, proposed corrections, a risk management 
interpretation, and additional metrics that should be added.

Headline finding: the provided score formula has the sign reversed — as 
written, the model would assign its highest (safest-looking) scores to its 
riskiest customers, the exact opposite of its stated design intent.

Full details are in 
[`exercise2_model_validation/exercise2_summary.md`](exercise2_model_validation/exercise2_summary.md), 
with the complete technical review in `model_validation_review.Rmd` 
(rendered as `model_validation_review.html` for easy reading without R).

## How to read this repository

Every notebook and document follows the same pattern: a short explanation 
of what is being calculated or reviewed and why it matters, followed by the 
work itself, followed by an interpretation of the result. Where a finding 
is actionable, this is stated explicitly.

All Jupyter notebooks render directly on GitHub with no setup required. 
The R Markdown review can be read either as the rendered `.html` file 
(opens in any browser) or as the source `.Rmd` file.

## Contact

Omkar Desai
desaiomkar767@gmail.com