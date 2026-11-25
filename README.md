# Forecasting U.S. Retail Sales with ARMA and SARIMA

**Time-series analysis in R | Independent modeling comparison | April 2026**

## At a glance

This project investigates **monthly U.S. retail sales for electronic shopping and mail-order houses** using 409 observations from **January 1992 through January 2026**. I explored the pronounced trend and annual seasonality in the data, then developed two approaches to forecast the next 24 months:

1. **Trend/seasonal decomposition + ARMA** on the remaining variation.
2. **Seasonal ARIMA (SARIMA)** directly on the log-transformed series.

The main goal was not just to generate forecasts, but to reason through the time-series structure, examine diagnostic evidence, and justify a modeling choice.

## Why this question?

Retail sales reflect changing consumer habits as well as predictable seasonal patterns. A series with long-run growth, changing variance, and holiday-related peaks presents a useful forecasting challenge: an apparently good fit can still leave temporal structure unexplained.

## Data

- **Source:** [Federal Reserve Economic Data (FRED)](https://fred.stlouisfed.org/series/MRTSSM4541USN), series `MRTSSM4541USN`
- **Measure:** U.S. retail sales for electronic shopping and mail-order houses, millions of dollars
- **Frequency:** Monthly; 409 observations; January 1992–January 2026
- **Included file:** [`data/5550RetailData.csv`](data/5550RetailData.csv) — historical extract used in the original project (not a live feed)

The dataset has a date column (`observation_date`) and sales column (`MRTSSM4541USN`). The analysis uses the original historical extract rather than automatically refreshing revised source values.

## Modeling approach

### 1. Explore and transform

I plotted the series, examined seasonality and autocorrelation, and used a **log transformation** to address the increasing variation as sales levels grew.

### 2. Trend/seasonal decomposition + ARMA

I decomposed the logged series into trend, seasonal, and residual components. An initial **AR(1)** model left seasonal autocorrelation, so I fitted an **ARMA(1,0) × (0,0,1)₁₂** model to the residuals, then examined the residual ACF/PACF. For forecasting, the original analysis extrapolated the final estimated trend level and repeated the seasonal pattern while forecasting the ARMA residual component.

### 3. SARIMA

I evaluated ordinary and seasonal differencing, compared candidate models using AIC, and selected **SARIMA(0,1,1) × (0,1,1)₁₂** on logged sales. I checked residual dependence and generated **24-month forecasts** with nominal 95% intervals on the original scale.

## Key findings

- The series displayed **strong long-run growth and annual seasonality**, including recurring year-end peaks.
- The decomposition residual model improved substantially over the initial AR(1) specification (**AIC −1504.28 vs. −1357.36**, as reported in the original analysis).
- Among two SARIMA candidates, the simpler selected model had **AIC −1364.579**, close to the larger alternative's **−1364.623** (a difference of approximately 0.044).
- Residual diagnostic plots in the report suggested the selected models captured most of the remaining serial structure.
- **SARIMA was preferred in the final report** for its more compact modeling framework and comparable diagnostics.

**Interpretation note:** AICs calculated for models fitted to different transformed/component series are **not a direct head-to-head test** of the two overall forecasting approaches. The original report includes that comparison; the stronger supported rationale is parsimony and diagnostic evidence within each model family. This project did **not** use a separate holdout set or rolling-origin backtest, so its future forecast accuracy is not established.

## Repository contents

```text
us-retail-sales-forecasting/
├── README.md
├── analysis.R                # Organized base-R analysis and forecasts
├── data/
│   └── 5550RetailData.csv    # Original 409-row historical extract
└── report/
    └── final_report.pdf      # Complete eight-page original report
```

## Reproduce the analysis

The script uses **base R only**; no additional packages are required.

1. Install R and open this repository as your working directory in RStudio (or use a terminal in the repository folder).
2. Run:

   ```r
   source("analysis.R")
   ```

3. Review the plots, printed model comparisons, and the `forecast_table` object containing 24 SARIMA forecast months.

The source script is an organized adaptation of my original course project. It keeps the original model specifications while improving relative file paths, input checks, and explicit forecast time indices. **The adapted script has not yet been executed and verified in this environment**; the original analysis and outputs are preserved in the PDF report.

## Limitations and next steps

- No out-of-sample backtesting was performed; rolling-origin validation would be an important next step.
- The decomposition forecast holds the final estimated trend level constant and repeats seasonal effects; its displayed uncertainty does not account for estimating or extrapolating those components.
- Back-transforming forecasts from a log scale yields median forecasts on the original scale unless a bias adjustment is applied.
- External shocks and structural shifts, such as the pandemic-era retail changes, may not be captured by a fixed-coefficient seasonal model.

## Author

**Cole Rajaratnam** · Statistics, The Ohio State University · Expected graduation May 2027
