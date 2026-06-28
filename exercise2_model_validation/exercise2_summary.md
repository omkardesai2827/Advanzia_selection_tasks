# Exercise 2 Summary — Model Validation Review

This is a short summary of my review of the R code provided for the 
behavioural credit scorecard. The full, detailed version with code 
references is in `model_validation_review.Rmd`; this is the quick-read 
version covering the same five points asked for in the brief.

## What I found wrong with the code

I found eight issues while going through the code line by line. The most 
serious one is that the score formula has the sign backwards as written, 
the model would give its highest (safest-looking) scores to the riskiest 
customers, not the safest ones, which is the exact opposite of what the 
brief asks for. 

Two other significant issues: the code mixes "last month's" data with 
"this month's" data when training the model, even though it's not supposed 
to mix the two and this month's data includes information that's 
basically baked into the answer the model is trying to predict, which makes 
the model look more accurate than it really is. On top of that, the model 
is tested on the exact same data it was trained on, so we have no real idea 
how it would perform on new customers it hasn't seen before.

The remaining issues are: the line meant to turn TRUE/FALSE into 1/0 
doesn't actually do that correctly, a column gets referenced that doesn't 
exist anywhere in the data (which would stop the code from running at 
all), the Brier score formula doesn't match its own textbook definition, 
and a missing data setting could let a single bad row silently wipe out an 
entire result without any warning.

## What's missing that should be there

Beyond the actual errors, there's a lot missing that I'd expect to see in a 
properly built and tested model.On the building side: no comparison of 
different model settings, no mention of how rare defaults are in this data 
(which usually needs special handling),and no simpler model used as a 
baseline to check if the more complex model is even worth it.

On the testing side: there's no check on whether the predicted probabilities 
are actually accurate, only on whether the ranking looks right. There's no 
check on whether the model's scores stay stable over time or across the 
different markets even though the results table is already split out by 
market and month, suggesting that was the original intent. And there's no 
look at which variables are actually driving the model's predictions, which 
makes it hard to explain or defend the model's decisions later.

## My fixes

I corrected all eight issues in a separate file (`corrected_code.R`). The 
two most important changes were: flipping the sign in the score formula so 
it points the right way, and properly separating the data into a training 
period and a separate, later testing period, so the reported results 
actually mean something about how the model would perform on new customers.

## What this means in practice

Even putting the formula errors aside, a model that's only ever been tested 
on data it already learned from shouldn't be trusted for real decisions
we just don't know how it would behave on customers it hasn't seen yet. The 
backwards score is the part I'd worry about most operationally: if this 
went live as-is, the bank would end up offering its best terms to its 
riskiest customers and chasing its safest customers for payment, simply 
because the scale is flipped. This is exactly the kind of problem that 
only shows up when someone actually checks the code carefully, rather than 
just looking at a final accuracy number which is the whole reason 
independent model checking exists as its own step before a model gets used.

## Other checks I'd add

Right now the code only reports AUC and a wrongly-calculated Brier score. 
I'd add: Gini and the KS statistic (both standard ways of checking the 
model ranks risky customers correctly), a Hosmer-Lemeshow test with a 
calibration table (to check whether the predicted probabilities themselves 
are accurate, not just the ranking), a way to track whether the scores 
drift over time across markets, and a look at which variables the model 
relies on most, since none of that is currently available.