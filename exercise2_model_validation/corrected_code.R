library(dplyr)
library(pROC)
library(randomForest)

#### Data preparation ####
# df is a data frame containing CustomerID, ForDate, MarketID, utilization_ratio, repayment_ratio, cash_share, balance,
# days_past_due, is_default

df2 <- df %>%
  arrange(CustomerID, ForDate) %>%
  group_by(CustomerID) %>%                     # FIX 1: group by customer before lagging, so lag() never pulls in another customer's value
  mutate(ForDate = as.Date(ForDate),
  # TARGET: default
  default = as.numeric(is_default),      # FIX 2: numeric() is used to create a new vector of zeros, while as.numeric() is used to convert an existing object into a numeric type.
  
  # FEATURES: lagged behaviour — ALL features lagged consistently (t-1),
  # none use same-period (t) values, removing target leakage (FIX 3)
  util_lag = lag(utilization_ratio),
  repay_lag = lag(repayment_ratio),
  cash_share_lag = lag(cash_share),
  balance_lag = lag(balance),
  dpd_lag = lag(days_past_due)
  ) %>%
  ungroup() %>%
  filter(!is.na(default), !is.na(util_lag), !is.na(repay_lag),  # FIX 4: also drop rows with NA in any feature, not just NA in the target
         !is.na(cash_share_lag), !is.na(balance_lag), !is.na(dpd_lag))

# FIX 5: train/test split
# Train on the earlier part of the period, test on the most recent months,
# so performance is assessed on data the model has not seen
cutoff_date <- quantile(df2$ForDate, 0.75, type = 1)   # last 25% of dates held out as test

train_df <- df2 %>% filter(ForDate <= cutoff_date)
test_df  <- df2 %>% filter(ForDate >  cutoff_date)

# Random Forest model — trained ONLY on the training period
set.seed(123)
model <- randomForest(
  x = train_df %>% select(util_lag, repay_lag, cash_share_lag, balance_lag, dpd_lag), # FIX 6: feature set now uses ONLY lagged (t-1) versions consistently — no leakage
  y = as.factor(train_df$default),
  ntree = 300
)


test_df$pd_hat <- predict(model,
                           newdata = test_df %>% select(util_lag, repay_lag, cash_share_lag,
                                                          balance_lag, dpd_lag), # fix 7: column names now match the lagged features used in training
                           type = "prob")[, "1"]
                           # "1" is correct here because as.factor(0/1) sorts levels as "0","1",
                           # so column "1" holds P(default=1). Always verify with
                           # colnames(predict(model, type="prob")) rather than assuming.

# Convert PD to score points — FIX 8: corrected sign
odds <- test_df$pd_hat / (1 - test_df$pd_hat)
test_df$score_points <- round(500 - 20 * log(odds))# Minus sign: lower PD -> higher score, matching the stated design intent

# Performance metrics per MarketID — FIX 9: corrected Brier score formula ----
perf <- test_df %>%
  group_by(ForDate, MarketID) %>%
  summarise(
    auc   = as.numeric(pROC::auc(pROC::roc(default, score_points, quiet = TRUE))),
    brier = mean((pd_hat - default)^2, na.rm = TRUE), # mean of SQUARED differences, not square of mean difference
    dr    = mean(default),
    n     = n(),
    .groups = "drop"
  )

print(perf)