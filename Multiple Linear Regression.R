---
output:
  pdf_document: default
  word_document: default
geometry: margin=0.5in
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
library("ggplot2")
library("psych")
library("car")
library("QuantPsyc")
library("corrplot")
library("memisc")
library("pastecs")
library("GGally")
library("plyr")
library("lm.beta")
library("tidyverse")
library("olsrr")
```

**AIM:**
To build a Multiple Linear Regression model to predict the quality of wine. 

## Exploring the data

There are two datasets, where each dataset has 12 features such as quality of wine, alcohol level, sugar and so on. All the features have continuous values except the quality of wine which is discrete variable bounded in the range 1-10(more the better). The red wine dataset has 1599 samples and white wine dataset has 4899 samples. We have
merged the two datasets into new dataset “wine” and added a factor variable with two levels (red, white) to denote
the color of wine. There were no missing values in the dataset, but there are duplicate values (1177) in the dataset.\


Visual inspection of scatter plots and inspection of minimum and maximum data points revealed no outliers. We
continued our analysis using entire dataset by removing duplicate values; checked using wine[duplicated(wine), ]\

```{r echo=FALSE}
red <- read.csv("C:/Users/vishw/Documents/winequality-red.csv",sep = ";",header = TRUE)
red$color<-"red"
#Assigning 0 to red

white <- read.csv("C:/Users/vishw/Documents/winequality-white.csv",sep = ";",header = TRUE)
white$color <-"white"
#Assigning 1 to white

wine <- rbind(red,white)
wine$color <- as.factor(wine$color)

#total 1177 duplicates removed
wine<-wine %>% dplyr::distinct()

#temp3<-wine[duplicated(wine),] used this to check the number of duplicate rows.

str(wine)
```



**Correlation between variables**

```{r fig.height=3, fig.width=6 , echo=FALSE}
ggcorr(wine[,1:12], nbreaks = 4, label = TRUE, palette="RdPu", label_size = 2.5, label_color = "white", hjust=.9 ,layout.exp=3.5)

```
\
We have used correlation matrix to select the predictor variables that have influence on the quality of wine. From the above, features like **residual sugar and density**, and **density and alcohol** are corelated with each other.
Also, none of the variables dispaly high correlation ranging from 0.8~1. 


*Multiple Linear Regression*\

**Assumptions to be tested *Prior* to constructing the model** \

**1)** All predictor variables must be quantitative or categorical, and outcome must be quantitative, continuous, and unbounded\
All predictor variables are quantitative while **color** is a categorical variable (with 2 levels). **Quality** is an ordinal categorical variable in the range 1-10. However, **for the purpose of analysis we are assuming** that the Quality of wine is a continuous interval variable.\

**2)** Predictor variables are not highly correlated with any other variable in the dataset.\
As seen by the correlation matrix above, we proceed by considering our predictor variables as not being higly correlated with any other predictors in the dataset.

**3)** Predictors are uncorrelated with external variables.\
We have not been able to test whether there are external variables. We thus assume that these are the only variables under consideration.

**4)** Checking non-zero variance between quality and color groups (Using Levene Test) \

```{r echo=FALSE}
leveneTest(quality ~ color, data=wine)
```

The result F= 3.9541, p=0.04681 is non-significant for the wine quality at 0.01 level of significance (the value in the Pr (>F) column
is more than .01). This indicates that the variances are similar between groups and the homogeneity of
variance assumption is applicable.

**Building the regression model**

**n1:** Model with all predictor variables.\
**n2:** Model after removing citric acid which has high p-value and cannot be trusted in the model .\
**n3:** Model after removing density; VIF = 22 (>10) and tolerance = 0.04 (<0.1), which indicates a serious problem.\
**n4:** Removing fixed acidity which has high p-value and cannot be trusted in the model.\

**Note** R-squared will be reduced as we are reducing the number of predictor variables, but it was important to remove variables with high multicollinearity and p values > 0.05 level of significance.

**Comparing the 4 models**
```{r echo=FALSE}

n1<-lm(quality~.,data=wine)

n2<-update(n1,~.- citric.acid - fitted - standardized.residuals -cooks -  residuals)

#checked multicollinearity for removing highly correlated variables using VIF 
#vif(n2)
#tolerance<-1/vif(n2)
#tolerance
#mean(vif(n2))

n3<-update(n2,~. - density)

n4<-update(n3,~. -fixed.acidity)

mtable(n1,n2,n3,n4)


```

**Summary for the chosen regression model : n4**

```{r echo=FALSE}
summary(n4)
```
**PREDICTING THE QUALITY OF WINE USING OUR REGRESSION MODEL (Model n4)**

**Predicted value for quality of wine with prediction intervals**
```{r echo=FALSE}
newValues=tibble(volatile.acidity=1,residual.sugar=3,chlorides=0.1,free.sulfur.dioxide=7,total.sulfur.dioxide=16,pH=3.43,sulphates=0.46,alcohol=10,color='red')

predict(n4, newdata = newValues, interval = "prediction", level=0.95)
```

In the given dataset, the quality given for the above datapoints is 5. Hence, the value of quality predicted by our model (4.696) is a close representation within the prediction interval significant at 95% .

**Checking the assumptions for multiple regressions (post model building)**

**1)** No perfect multicollinearity (predictor variables should not correlate highly):

**a)** VIF value is <10 and Tolerance is greater than 0.1 and 0.2

```{r fig.height=3, fig.width=12 , echo=FALSE}
ols_vif_tol(n4)
```

**b)** Average is closer to 1, in our case it is 2.11 that indicates no high corelation i.e. variables do not corelate highly.
```{r echo=FALSE}
mean(vif(n4))
```

**2)** Residuals are Linear, Normal and Homoscedastic (constant variance) 

```{r fig.height=4, fig.width=8, echo=FALSE}
par(mfrow=c(2,2))
plot(n4)
```
**From the plots we observe the following:** 

**a)** The residuals are linear\
Residuals vs Fitted is used to check the linear relationship assumptions. A horizontal line, without distinct patterns is an indication for a linear relationship.

**b)** The residuals are normal\
Normal Q-Q is used to examine whether the residuals are normally distributed. It’s good if residuals points follow the straight dashed line which is almost normal in our case.

**c)** Homogenity of variance not observed\
Scale-Location (or Spread-Location). Used to check the homogeneity of variance of the residuals (homoscedasticity). 
Horizontal line with equally spread points is a good indication of homoscedasticity. This is not the case in our dataset, where we have a heteroscedasticity problem.

**d)** Residuals vs Leverage. Used to identify influential cases, that is extreme values that might influence the regression results when included or excluded from the analysis. Further analysis done below using Cook's distance.

**3)** Residuals are independent ( via Durbin-Watson test)

```{r echo=FALSE}
durbinWatsonTest(n4)
```
**Null Hypothesis**: Linear Regression residuals of wine are uncorrelated.\
**Alternate Hypothesis**: Linear Regression residuals of wine are autocorrelated. 

**The Durbin-Watson test** for independent errors was significant at the 5% level of significance
(d=1.77,p=0).Despite d=1.77 which doesn’t imply autocorrelation, a significantly small p-value (=0) casts doubt on the validity of the null hypothesis and indicates autocorrelation among residuals. This implies that the model has not accounted for all signals and thus, it consists of signal plus noise.

**4)** Checking for outliers and influential points 

**taking standardized residuals to check for outliers** 

```{r echo=FALSE}
wine$fitted <- n4$fitted
wine$residuals <- n4$residuals
wine$standardized.residuals <- rstandard(n4)

possible.outliers <- subset(wine, standardized.residuals < -1.96 | standardized.residuals > 1.96)
dim(possible.outliers)
```

301 observations lie above or below 1.96 standard deviations. As this represents 5.6% of the observations,
expected if the residuals are normal (5% of data is expected to be outside of 2 standard deviations),
we do not consider any of these observations as outliers and continued with all 301 observations
included in the model.\

**Cook's distance to find out the influential cases** \

```{r fig.height=3, fig.width=6 , echo=FALSE}
par(mfrow=c(1,1))
wine$cooks <- cooks.distance(n4)
plot(sort(wine$cooks, decreasing=TRUE))
max(wine$cooks)
```

Maximum cook's distance is 0.195, far below the threshold value of 1, so we conclude that there are no influential cases.


**CONCLUSION and FUTURE WORK**

1. Multiple Linear Regression model was built to predict the quality of wine using the significant variables  volatile acidity,residual sugar, chlorides, free sulfur dioxide, total sulfur dioxide, pH, sulphates, alcohol and color.\
2. Backward-Elimination-Method was used to create this regression model (all predictors entered simultaneously
without any order) and then removing predictors that were not significant or failed multicollinearity assumption.
All the incorporated predictor variables have an influence on the wine quality at 5% level of significance.\
3. Multiple R-squared value is 0.3056 and Adjusted R- squared value is 0.3044. Hence, our model explains 30.44%
variance in the Wine Quality and generalizes the population as well. The remaining 69.56% remains unexplained.\
4. One standard deviation change in the value of alcohol brings 0.458 (using lm.beta(n4)) standard deviation of
change in wine quality. Therefore, alcohol has highest impact on quality of wine.\
5. Further work can be done by finding out the quality and type of grape that was used to make wine and the
storing conditions as well.\

**References**
[1] Andy Field, Jeremy Miles, Zor Field, Discovering Statistics using R, Chapter 7 - Regression, SAGE Publication Ltd.\
[2] Paulo Cortez, Ant´onio Cerdeira, Modeling wine preferences by data mining from physicochemical properties