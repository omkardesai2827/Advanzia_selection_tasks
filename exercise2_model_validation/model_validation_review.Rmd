---
title: "Model Validation Review"
author: "Omkar Desai"
date: "`r Sys.Date()`"
output: html_document
---


## Context

This document reviews the R code given in Section 2 of the test case. The 
code builds a Random Forest model to estimate Probability of Default (PD — 
the chance a customer defaults), turns that PD into a score, and then 
calculates AUC and Brier score by `MarketID`.

I've gone through the code line by line and organised my findings into the 
five parts asked for in the brief:

1. Coding and logical errors
2. What's missing in how the model was built and tested
3. My proposed fixes, and why each one is needed
4. What this means from a risk management point of view
5. Other metrics I would add

The original code is kept exactly as given in `original_code.R`. My fixed, 
working version is in `corrected_code.R`. I've quoted the relevant lines 
from both files below so each point is easy to check.


## 1. Coding and Logical Errors

### 1.1 Wrong function used to convert the target into numbers

```r
default = numeric(is_default)
```

`numeric()` doesn't convert anything, it just creates a brand new vector 
full of zeros. The function that actually converts a logical column 
(TRUE/FALSE) into numbers (1/0) is `as.numeric()`. As written, this line 
will not give you the 0/1 default flag you actually need for the model.

### 1.2 Lag() used without grouping by customer first

```r
df2 <- df %>%
  arrange(CustomerID, ForDate) %>%
  mutate(
    util_lag = lag(utilization_ratio),
    repay_lag = lag(repayment_ratio),
    ...
  )
```

The data is sorted by customer and date, but `lag()` (which grabs the 
previous row's value, used to look at last month's behaviour) is applied 
without telling R to keep each customer separate first. This means for the 
very first month of every customer (except the first customer in the whole 
dataset), the "previous month" value it grabs actually belongs to a 
**different customer** whoever happened to be sitting in the row above. 
This needs a `group_by(CustomerID)` before the lagging happens, so each 
customer's history stays its own.

### 1.3 The model is partly trained on information it shouldn't have

```r
model <- randomForest(
  x = df2 %>% select(util_lag, repay_lag, cash_share, balance, days_past_due),
  y = as.factor(df2$default),
  ...
)
```

Look closely: two of the five inputs (`util_lag`, `repay_lag`) are lagged 
meaning they use last month's value. But the other three (`cash_share`, 
`balance`, `days_past_due`) are this month's values, even though lagged 
versions of all three were already created earlier in the code and then 
never actually used.

This is a problem because the target itself (`default`) is defined directly 
from `days_past_due` in that same month. So the model is being handed a 
variable that is basically baked into the answer it's trying to predict. 
This is called **data leakage** (when the model sees information it 
wouldn't actually have at the time it needs to make a real prediction)
and it will make the model look much more accurate than it really is.

### 1.4 A column is referenced that doesn't exist

```r
newdata = df2 %>% select(util_lag, repay_lag, cash_share, balance, dpd)
```

This line tries to use a column called `dpd`, but that column was never 
created, the actual column is named `days_past_due`, and its lagged 
version is `dpd_lag`. As written, this would simply throw an error in R, so 
the code can't even run as-is.

### 1.5 The score formula has the sign backwards

```r
df2$score_points <- round(500 + 20 * log(odds))
```

The brief says clearly: a lower PD (less risky customer) should give a 
**higher** score. But as PD goes up, the odds go up, and `log(odds)` (the 
log-odds: a transformed version of probability that can go negative or 
positive, used to make the score behave nicely) goes up too. With a **plus** 
sign here, that means a riskier customer (higher PD) ends up with a 
**higher** score exactly backwards. The fix is simple: change the plus 
to a minus, so `500 - 20 * log(odds)`.

### 1.6 The Brier score formula doesn't match its own definition

```r
brier = (mean(pd_hat - default, na.rm = FALSE))^2
```

The brief itself defines Brier score as the mean **squared** error meaning 
you square each individual error first, then average those squared values: 
`mean((pd_hat - default)^2)`. This code does it the other way round: it 
averages the raw errors first, and only squares that single average at the 
end. The problem with doing it this way is that positive errors and 
negative errors can cancel each other out before the squaring even happens, 
which can make a genuinely bad model look like it has a great (low) Brier 
score.

### 1.7 `na.rm = FALSE` makes missing values break the whole calculation

```r
brier = (mean(pd_hat - default, na.rm = FALSE), ...)
```

Because of the lagging bug above, some rows could end up with missing 
values. With `na.rm = FALSE`, R won't ignore those missing values when 
averaging, it will just return `NA` for that entire group instead. So one 
bad row can silently wipe out the whole Brier score for a market or month, 
with nothing in the output to flag that it happened.

### 1.8 The model is tested on the same data it was trained on

```r
df2$pd_hat <- predict(model,
                       newdata = df2 %>% select(...),
                       type = "prob")[, "1"]
```

The model is trained on `df2`, and then predictions are made on `df2` again 
— the exact same rows. This means every AUC and Brier score we get afterward 
only tells us how well the model fits data it has already seen, not how it 
would actually perform on new customers it's never encountered. I cover 
this in more depth in the next section, since it's really a methodology gap 
as much as a coding mistake.


## 2. What's Missing in How the Model Was Built and Tested

### 2.1 Gaps in how the model was built

- **No proper train/test split.** As mentioned above, the model is checked 
  against the same data it learned from. To actually know how good a model 
  is, you need to test it on data it has never seen usually by training 
  on earlier months and testing on the most recent ones, since this is 
  monthly customer data, not a random sample.

- **No reasoning given for `ntree = 300`.** This number (how many decision 
  trees the Random Forest builds) is just picked with no explanation or 
  comparison to other values like 100, 500, or 1000 to see what actually 
  works best.

- **No mention of how imbalanced the data is.** In most credit portfolios, 
  defaults are rare compared to non-defaults. The code never checks or 
  reports what percentage of customers actually defaulted, and it doesn't 
  do anything to help the model deal with that imbalance (for example, 
  giving more weight to the rarer default cases).

- **No simpler model to compare against.** There's no comparison to 
  something simpler like logistic regression, so we can't tell if the 
  extra complexity of a Random Forest is actually worth it here.

### 2.2 Gaps in how the model's results were checked

- **No check on whether the predicted probabilities are actually accurate 
  (calibration).** AUC only tells you if the model correctly ranks risky 
  customers above safe ones, it doesn't tell you if a customer the model 
  says has a "10% chance of default" really does default about 10% of the 
  time. To check that, you'd want something like a calibration table: sort 
  customers into groups by their predicted PD, and compare each group's 
  average predicted PD against what actually happened in that group. The 
  code never does this, so we genuinely don't know if the PD numbers 
  themselves can be trusted, even if the ranking looks fine.

- **No check on whether the model stays stable over time or across 
  markets.** The results table is already split out by `MarketID` and by 
  month, which tells me whoever wrote this wanted to compare performance 
  across markets and time, but it stops at AUC and Brier score per group. 
  It never actually checks whether the **scores themselves** are shifting 
  in a way that would be a red flag: for example, if the typical score in 
  one market starts drifting noticeably away from where it was when the 
  model was first built. That kind of check (comparing how the distribution 
  of scores looks now versus when the model was developed) is something I 
  would expect to see here, given the table is already broken down by 
  market and month.

- **No variable importance output.** `randomForest` natively provides this 
  via `importance()`, and omitting it means there is no visibility into 
  which behavioural variables are actually driving the PD estimates, which is 
  relevant both for business insight and for explainability/governance 
  requirements.

- **No sense of how confident we should be in the AUC and Brier numbers.** 
  These are reported as single numbers per market and month, with nothing 
  telling us how much they might vary just by chance, especially risky if 
  some markets only have a small number of customers in a given month.

- **No checks on the data itself before using it.** There's no evidence 
  anyone looked for weird outliers, impossible values, or missing data in 
  the raw columns before feeding them into the model.


## 3. My Proposed Fixes, and Why Each One Is Needed

The full fixed version of the code is in `corrected_code.R`. Here's each 
problem from above, matched to the fix I made, and why it actually matters.

**1. `numeric(is_default)` -> `as.numeric(is_default)`**
`as.numeric()` is the correct way to turn TRUE/FALSE into 1/0. Without this 
fix, the target column the model learns from could be wrong from the very 
start.

**2. `lag()` without grouping -> added `group_by(CustomerID)` before lagging, 
then `ungroup()` right after**
This makes sure each customer's "last month" value only ever comes from 
their own history, not from whoever happens to be sitting in the row above 
them in the table.

**3. Mixed lagged and same-month features -> all five features now use the 
lagged (last month) version consistently**
This removes the data leakage problem. The model can no longer "cheat" by 
seeing information from the same month it's trying to predict, so whatever 
performance it shows afterward is a fair reflection of what it can actually 
do, not an inflated number.

**4. `dpd` column didn't exist -> corrected to `dpd_lag`, matching what was 
actually built earlier in the code**
Without this, the code simply won't run.

**5. Score formula had the wrong sign -> changed to `500 - 20 * log(odds)`**
This restores what the brief actually asked for: a safer customer (lower 
PD) should get a higher score, not a lower one. Without this fix, anyone 
using this score to make decisions, who to approve, who to chase for 
payment — would be doing the exact opposite of what they intended.

**6. Brier score formula -> changed to `mean((pd_hat - default)^2, na.rm = TRUE)`**
This matches the actual definition given in the brief: average the squared 
errors, don't square the average. The original version can hide how 
inaccurate the model really is.

**7. No train/test split -> added one based on date, training on the 
earliest 75% of months and testing on the most recent 25%**
This is the single most important fix. Testing the model on months it has 
never seen is the only way to get a genuine idea of how well it would 
perform on real, new customers going forward.

**8. `na.rm = FALSE` -> changed to `na.rm = TRUE`, and added a step to also 
remove rows where any of the features are missing (not just the target)**
This stops one missing value from silently wiping out an entire market's 
results with no warning.


## 4. What This Means From a Risk Management Point of View

Even if every line of code here were technically correct, a model that has 
only ever been tested on the data it was trained on shouldn't be trusted 
for real decisions — we simply don't know how it would behave on customers 
it hasn't already seen.

The score direction issue is the one I'd flag as the most serious in 
practice. As written, the bank would end up giving its **best** scores to 
its **riskiest** customers, because the whole scale is flipped. If this 
went live, it would mean offering the wrong customers higher credit limits, 
chasing the wrong customers for late payments, and generally making every 
score-based decision backwards, not a small rounding error, but a 
complete reversal of what the score is meant to do.

The data leakage issue is serious in a quieter way: even once the formulas 
are fixed, the model's AUC and Brier score will still look better than they 
really are, because part of what it's "predicting" with is information that 
wouldn't actually be available at the moment a real prediction needs to be 
made.

This is really the whole point of having someone independent check a model 
before it's used these are exactly the kinds of problems that don't show 
up just by glancing at a final AUC number. You only catch them by actually 
going through the code line by line and checking it against what the model 
is supposed to be doing.


## 5. Other Metrics I Would Add

Right now the code only reports AUC and a (wrongly calculated) Brier score. 
For a model like this, I'd want to see more, grouped into three areas:

**Checking the ranking (discrimination):**

- **Gini** (just AUC rescaled — Gini = 2 x AUC - 1) it's the same 
  information as AUC, but it's the number people in credit risk are more 
  used to talking about.
- **KS statistic** looks at the biggest gap between how defaulters and 
  non-defaulters are spread out across score bands. Another standard way to 
  check how well the model separates the two groups.

**Checking the actual probability numbers (calibration):**

- A **Hosmer-Lemeshow test with a decile-level calibration table** sorts
  customers into 10 groups by predicted PD, then compare each group's 
  average predicted PD against its actual default rate. If the model is 
  well calibrated, these two numbers should be close in every group. This 
  tells us something AUC cannot: not just whether risky customers are 
  ranked above safe ones, but whether a customer labelled "10% likely to 
  default" really does default about 10% of the time which matters if 
  these PDs are ever used for setting credit limits or calculating expected 
  losses, not just for ranking customers.

**Checking it stays stable over time**

- A way to track whether the **scores themselves are drifting** compared to 
  when the model was first built across the different markets and months 
  already shown in the results table. If the scores start looking very 
  different from how they looked originally, that's a sign the model might 
  need to be retrained or recalibrated.

**Making it explainable**

- **Which variables actually drive the model's predictions:** Random Forest 
  gives you this almost for free, it's just never asked for in the code. 
  Knowing this helps explain *why* the model makes the calls it makes, 
  which matters both for understanding the customers and for being able to 
  justify the model later if anyone questions it.
- Some sense of **how much the AUC and Brier numbers could vary by chance**, 
  especially since some markets or months might only have a handful of 
  customers in them.