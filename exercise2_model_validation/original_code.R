library(dplyr)
library(pROC)
library(randomForest)

#### Data preparation ####
# df is a data frame containing CustomerID, ForDate, MarketID, utilization_ratio, repayment_ratio, cash_share, balance,
# days_past_due, is_default
df2 <- df %>%
    arrange(CustomerID, ForDate) %>%
    mutate(ForDate = as.Date(ForDate),
    
    # TARGET: default
    default = numeric(is_default),
    
    # FEATURES: lagged behaviour
    util_lag = lag(utilization_ratio),
    repay_lag = lag(repayment_ratio),
    cash_share_lag = lag(cash_share),
    balance_lag = lag(balance),
    dpd_lag = lag(days_past_due)
    ) %>%
    filter(!is.na(default))

# Random Forest model
set.seed(123)
model <- randomForest(
  x = df2 %>% select(util_lag, repay_lag, cash_share, balance, days_past_due),
  y = as.factor(df2$default),
  ntree = 300
)

# Prediction (prob of class "1")
df2$pd_hat <- predict(model,
                       newdata = df2 %>% select(util_lag, repay_lag, cash_share, balance, dpd),
                       type = "prob")[, "1"]

# Convert PD to score points
odds <- df2$pd_hat / (1 - df2$pd_hat)
df2$score_points <- round(500 + 20 * log(odds))

# Performance metrics per MarketID
perf <- df2 %>%
  group_by(ForDate, MarketID) %>%
  summarise(
    auc = as.numeric(auc(roc(default, score_points))),
    brier = (mean(pd_hat - default, na.rm = FALSE))^2,
    dr = mean(default),
    n = n(),
    .groups = "drop"
  )

print(perf)