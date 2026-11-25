# U.S. Retail Sales Forecasting: Decomposition/ARMA and SARIMA
# Original STAT 5550 analysis by Cole Rajaratnam (April 2026).
# Repository adaptation: consistent relative paths and forecast time indices.
# Uses base R only. Run from the repository root: source("analysis.R")

# 1. Load and validate the original monthly FRED series
sales_data <- read.csv("data/5550RetailData.csv", stringsAsFactors = FALSE)
stopifnot(all(c("observation_date", "MRTSSM4541USN") %in% names(sales_data)))
sales_data$observation_date <- as.Date(sales_data$observation_date)
sales_data <- sales_data[order(sales_data$observation_date), ]
stopifnot(nrow(sales_data) == 409L,
          !anyNA(sales_data[, c("observation_date", "MRTSSM4541USN")]),
          all(sales_data$MRTSSM4541USN > 0),
          identical(sales_data$observation_date,
                    seq(as.Date("1992-01-01"), as.Date("2026-01-01"), by = "month")))

sales_ts <- ts(sales_data$MRTSSM4541USN, start = c(1992, 1), frequency = 12)
log_sales_ts <- log(sales_ts)
forecast_start <- c(2026, 2) # First month after the final observation

# Exploratory time series and seasonal pattern
plot(sales_ts, main = "Monthly U.S. Retail Sales: Electronic Shopping and Mail-Order Houses",
     ylab = "Millions of dollars", xlab = "Year")
monthplot(sales_ts, main = "Seasonal Pattern of U.S. Retail Sales",
          ylab = "Millions of dollars")

# 2. Decomposition followed by seasonal ARMA on residuals
decomp <- decompose(log_sales_ts, type = "additive")
plot(decomp)
residuals_ts_clean <- na.omit(decomp$random)
acf(residuals_ts_clean, main = "ACF After Decomposition")
pacf(residuals_ts_clean, main = "PACF After Decomposition")

model_arma1 <- arima(residuals_ts_clean, order = c(1, 0, 0))
model_arma2 <- arima(residuals_ts_clean, order = c(1, 0, 0),
                     seasonal = list(order = c(0, 0, 1), period = 12))
cat("Decomposition residual model AICs:\n")
print(c(AR1 = model_arma1$aic, Seasonal_ARMA = model_arma2$aic))

resid_arma2 <- residuals(model_arma2)
par(mfrow = c(3, 1))
plot(resid_arma2, main = "Decomposition + ARMA Residuals")
acf(resid_arma2, main = "Residual ACF")
pacf(resid_arma2, main = "Residual PACF")
par(mfrow = c(1, 1))

forecast_arma <- predict(model_arma2, n.ahead = 24)
last_trend <- tail(na.omit(decomp$trend), 1)
last_seasonal <- tail(decomp$seasonal, 12)
trend_future <- rep(as.numeric(last_trend), 24)
seasonal_future <- rep(as.numeric(last_seasonal), length.out = 24)
yhat_log <- trend_future + seasonal_future + as.numeric(forecast_arma$pred)
yhat <- ts(exp(yhat_log), start = forecast_start, frequency = 12)
# Approximate bounds conditional on the extrapolated trend and seasonal effects;
# these omit uncertainty from estimating/extrapolating those components.
lower_arma <- ts(exp(yhat_log - 1.96 * as.numeric(forecast_arma$se)),
                 start = forecast_start, frequency = 12)
upper_arma <- ts(exp(yhat_log + 1.96 * as.numeric(forecast_arma$se)),
                 start = forecast_start, frequency = 12)

plot(sales_ts, xlim = c(1992, 2028), ylim = c(0, 250000),
     main = "Decomposition + ARMA Forecast", ylab = "Millions of dollars", xlab = "Year")
lines(yhat, col = "blue", lwd = 2)
lines(lower_arma, col = "red", lty = 2)
lines(upper_arma, col = "red", lty = 2)

# 3. SARIMA models on the logged original series
acf(log_sales_ts, main = "ACF of Logged Sales")
diff1 <- diff(log_sales_ts)
diff2 <- diff(diff1, lag = 12)
plot(diff1, main = "First Difference of Logged Sales")
acf(diff1, main = "ACF After First Differencing")
plot(diff2, main = "First and Seasonal Differencing")
acf(diff2, main = "ACF After Both Differences")
pacf(diff2, main = "PACF After Both Differences")

model_sarima <- arima(log_sales_ts, order = c(0, 1, 1),
                      seasonal = list(order = c(0, 1, 1), period = 12))
model_sarima_alt <- arima(log_sales_ts, order = c(1, 1, 1),
                          seasonal = list(order = c(0, 1, 1), period = 12))
cat("SARIMA AIC comparison:\n")
print(c(Selected = model_sarima$aic, Alternative = model_sarima_alt$aic))
print(model_sarima)

resid_sarima <- residuals(model_sarima)
par(mfrow = c(3, 1))
plot(resid_sarima, main = "SARIMA Residuals")
acf(resid_sarima, main = "SARIMA Residual ACF")
pacf(resid_sarima, main = "SARIMA Residual PACF")
par(mfrow = c(1, 1))

forecast_sarima <- predict(model_sarima, n.ahead = 24)
yhat_sarima <- ts(exp(as.numeric(forecast_sarima$pred)),
                  start = forecast_start, frequency = 12)
lower_sarima <- ts(exp(as.numeric(forecast_sarima$pred) -
                       1.96 * as.numeric(forecast_sarima$se)),
                   start = forecast_start, frequency = 12)
upper_sarima <- ts(exp(as.numeric(forecast_sarima$pred) +
                       1.96 * as.numeric(forecast_sarima$se)),
                   start = forecast_start, frequency = 12)

plot(sales_ts, xlim = c(1992, 2028), ylim = c(0, 250000),
     main = "SARIMA Forecast", ylab = "Millions of dollars", xlab = "Year")
lines(yhat_sarima, col = "blue", lwd = 2)
lines(lower_sarima, col = "red", lty = 2)
lines(upper_sarima, col = "red", lty = 2)

# Save a compact table of future point forecasts and nominal 95% SARIMA bounds.
# Exponentiated log forecasts are medians on the original sales scale.
forecast_table <- data.frame(
  month = format(seq(as.Date("2026-02-01"), by = "month", length.out = 24), "%Y-%m"),
  sarima_median_forecast = as.numeric(yhat_sarima),
  sarima_lower_95 = as.numeric(lower_sarima),
  sarima_upper_95 = as.numeric(upper_sarima)
)
cat("\nFirst six forecast months (sales in millions of dollars):\n")
print(head(forecast_table))
