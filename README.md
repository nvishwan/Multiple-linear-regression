# Predicting Wine Quality with Multiple Linear Regression

An R Markdown analysis that builds and validates a multiple linear regression model to predict the quality score (1–10) of Portuguese *Vinho Verde* wine from its physicochemical properties.

## Dataset

Two datasets from the UCI Wine Quality collection (Cortez et al.):

| File | Samples |
|---|---|
| `winequality-red.csv` | 1,599 |
| `winequality-white.csv` | 4,899 |

Each sample has 11 physicochemical measurements (fixed/volatile acidity, citric acid, residual sugar, chlorides, free/total sulfur dioxide, density, pH, sulphates, alcohol) plus a `quality` score. The two files are merged, a `color` factor (red/white) is added, and 1,177 duplicate rows are removed. There are no missing values.

## Approach

1. **Explore** the data and inspect pairwise correlations.
2. **Check assumptions before modelling**: variable types, low predictor correlation, and homogeneity of variance (Levene's test across wine color).
3. **Build four models** by backward elimination, dropping predictors with high p-values (`citric.acid`, `fixed.acidity`) or severe multicollinearity (`density`, VIF ≈ 22).
4. **Predict** quality for a new sample with a 95% prediction interval.
5. **Validate the final model**: VIF/tolerance, residual diagnostics (linearity, normality, homoscedasticity), Durbin-Watson independence test, standardized residuals for outliers, and Cook's distance for influential points.

## Key results

- Final model predictors: volatile acidity, residual sugar, chlorides, free and total sulfur dioxide, pH, sulphates, alcohol, and color.
- R² = 0.306 (adjusted R² = 0.304): the model explains about 30% of the variance in quality.
- **Alcohol** has the strongest effect: a one-standard-deviation increase raises quality by about 0.46 standard deviations.
- No influential points (maximum Cook's distance 0.195, well under 1).
- Limitations: the residuals show heteroscedasticity and some autocorrelation, and quality is an ordinal score treated as continuous. These suggest trying other model types.

## Repository contents

| File | Description |
|---|---|
| `Multiple Linear Regression.Rmd` | Full analysis (R Markdown source) |
| `Multiple Linear Regression.pdf` | Rendered report |
| `winequality-red.csv`, `winequality-white.csv` | Input data (`;`-separated) |

## Running it

Install the required packages, then knit from the repository root, since the CSVs are read by relative path:

```r
install.packages(c("ggplot2", "psych", "car", "QuantPsyc", "corrplot", "memisc",
                   "pastecs", "GGally", "plyr", "lm.beta", "tidyverse", "olsrr", "rmarkdown"))
rmarkdown::render("Multiple Linear Regression.Rmd")
```

## References

- A. Field, J. Miles, Z. Field. *Discovering Statistics Using R*, Ch. 7 (Regression). SAGE.
- P. Cortez, A. Cerdeira, et al. *Modeling wine preferences by data mining from physicochemical properties.*
