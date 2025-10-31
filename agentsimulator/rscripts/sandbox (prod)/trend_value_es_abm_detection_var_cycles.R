
## ------------- DETECTION OF VAR/ES CYCLES ---------------- ##

rm(list = ls())        # clear objects
graphics.off()         # close graphics windows
library(reshape)       # plotting ggplots
library(ggplot2)
library(zoo)
library(grid)          # plotting ggplots in a grid
library(TTR)           # calculation of MA's
library(dplyr)
library(purrr)
library(tibble)
library(tidyr)

options(tibble.print_max = Inf)   # always show all rows of tibbles (can be huge)
options(tibble.width = Inf)       # don’t truncate columns


###################################################################
#                                                                 #
#               'PARAMETERS' & INITIAL INFORMATION                #
#                                                                 #
###################################################################

nAssets = 1
nExp = 11
volWindow = 20       # Window used to calculate volatility
N_FUND = 200
N_TREND = 200

# Setting the path to the data folder
# Set the root directory (add your path)
root.dir <- "C:/Users/bllac/eclipse-workspace/eclipse_DB"

# Build the home directory (shouldn't be necessary to change)
home.dir <- paste(root.dir, "/agentsimulator/out/trend-value-es-abm-simulation/", sep="")


# ------------ READ & STACK EXPERIMENT FILES IN ORDER ------------- #

read_exp <- function(e, stem) {
  read.table(
    paste0(home.dir, stem, "E", e, ".csv"),
    header = TRUE, sep = ",", na.strings = "NA", dec = ".", strip.white = TRUE
  )
}

# E0 first
tsprices                 <- read_exp(0, "list_price_timeseries_")
tsFUNDvarselloffvolume   <- read_exp(0, "list_fundvarselloffvolume_timeseries_")
tsTRENDvarselloffvolume  <- read_exp(0, "list_trendvarselloffvolume_timeseries_")
tsFUNDesselloffvolume    <- read_exp(0, "list_fundesselloffvolume_timeseries_")
tsTRENDesselloffvolume   <- read_exp(0, "list_trendesselloffvolume_timeseries_")
tsFUNDhittingvar         <- read_exp(0, "list_fundshittingVar_timeseries_")
tsTRENDhittingvar        <- read_exp(0, "list_trendshittingVar_timeseries_")
tsFUNDhittinges          <- read_exp(0, "list_fundshittingEs_timeseries_")
tsTRENDhittinges         <- read_exp(0, "list_trendshittingEs_timeseries_")

if (nExp > 1) {   # Read data for single experiments and merge them
  for (e in 1:(nExp - 1)) {
    tsprices                <- dplyr::left_join(tsprices,                read_exp(e, "list_price_timeseries_"),                 by = "tick")
    tsFUNDvarselloffvolume  <- dplyr::left_join(tsFUNDvarselloffvolume,  read_exp(e, "list_fundvarselloffvolume_timeseries_"), by = "tick")
    tsTRENDvarselloffvolume <- dplyr::left_join(tsTRENDvarselloffvolume, read_exp(e, "list_trendvarselloffvolume_timeseries_"),by = "tick")
    tsFUNDesselloffvolume   <- dplyr::left_join(tsFUNDesselloffvolume,   read_exp(e, "list_fundesselloffvolume_timeseries_"),  by = "tick")
    tsTRENDesselloffvolume  <- dplyr::left_join(tsTRENDesselloffvolume,  read_exp(e, "list_trendesselloffvolume_timeseries_"), by = "tick")
    tsFUNDhittingvar        <- dplyr::left_join(tsFUNDhittingvar,        read_exp(e, "list_fundshittingVar_timeseries_"),      by = "tick")
    tsTRENDhittingvar       <- dplyr::left_join(tsTRENDhittingvar,       read_exp(e, "list_trendshittingVar_timeseries_"),     by = "tick")
    tsFUNDhittinges         <- dplyr::left_join(tsFUNDhittinges,         read_exp(e, "list_fundshittingEs_timeseries_"),       by = "tick")
    tsTRENDhittinges        <- dplyr::left_join(tsTRENDhittinges,        read_exp(e, "list_trendshittingEs_timeseries_"),      by = "tick")
  }
}


# ----------------- DIMENSIONS & CONSISTENCY CHECK ---------------- #

nTicks <- nrow(tsprices)
nCols  <- ncol(tsprices) - 1  # exclude 'tick'

# deduce nRuns from total columns
stopifnot(nCols %% (nExp * nAssets) == 0)
nRuns <- as.integer(nCols / (nExp * nAssets))

message(sprintf("Detected: nExp=%d, nRuns=%d, nAssets=%d (total series=%d)", nExp, nRuns, nAssets, nCols))

# # Change titles of dataframe columns to more descriptive ones (asset, then run, then experiment)
era_name <- function(e, r, a) sprintf("E%d_R%d_A%d", e, r, a)
titles <- "tick"
for (e in 1:nExp) {
  for (r in 1:nRuns) {
    for (a in 1:nAssets) {
      titles <- append(titles, era_name(e, r, a))
    }
  }
}

colnames(tsprices)                <- titles
colnames(tsFUNDvarselloffvolume)  <- titles
colnames(tsTRENDvarselloffvolume) <- titles
colnames(tsFUNDesselloffvolume)   <- titles
colnames(tsTRENDesselloffvolume)  <- titles
colnames(tsFUNDhittingvar)        <- titles
colnames(tsTRENDhittingvar)       <- titles
colnames(tsFUNDhittinges)         <- titles
colnames(tsTRENDhittinges)        <- titles



# ----------------- Indexer: map (E,R,A) → column index ---------------- #

# 1-based (E,R,A) -> column index in data frames (1= 'tick')
era_col_idx <- function(e, r, a, nRuns, nAssets) {
  1 + ((e - 1) * nRuns + (r - 1)) * nAssets + a
}


# ------------- Rolling standard deviation, right-aligned ---------------- #

roll_sd  <- function(x, w) zoo::rollapply(x, w, sd,      align = "right", fill = NA, na.rm = TRUE)



###################################################################
#                                                                 #
#                            SIGNALS                              #
#                                                                 #
###################################################################

## These functions construct the time series needed by 
## the detector for a given run (column)

## ---------------------- Signals: VaR version -------------------------- ##

# Build signals for VaR cycles:
#  - F := varselloff volume (FUND + TREND)
#  - b := synchronization from hittingVar counts
#  - sigma from price returns

build_signals_var_for_era <- function(e, r, a,
                                      tsprices,
                                      tsFUNDvarselloffvolume,
                                      tsTRENDvarselloffvolume,
                                      tsFUNDhittingvar,
                                      tsTRENDhittingvar,
                                      w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200) {
  col <- era_col_idx(e, r, a, nRuns, nAssets)
  price <- as.numeric(tsprices[[col]])
  Tlen  <- length(price)
  rts   <- c(NA_real_, diff(base::log(price)))
  sigma <- roll_sd(rts, w_sigma)

  # VaR forced-liquidations flow (volume)
  F <- as.numeric(tsFUNDvarselloffvolume[[col]]) +
       as.numeric(tsTRENDvarselloffvolume[[col]])

  # Synchronization proxy b_t from "hittingVar" counts
  # (fraction of agents simultaneously constrained by risk limits)
  hit_var <- as.numeric(tsFUNDhittingvar[[col]]) +
             as.numeric(tsTRENDhittingvar[[col]])
  b <- pmin(1, hit_var / (N_FUND + N_TREND))

  tibble(
    t = seq_len(Tlen),
    price = price,
    r = rts,
    sigma = sigma,
    sigma_base = TTR::EMA(sigma, n = ema_sigma_L),  # Slow baseline (EMA) to detect regime shifts vs noise
    F = F,
    F_base = TTR::EMA(F, n = ema_F_L),
    b = b
  )
}

## ---------------------- Signals: ES version --------------------------- ##

# Build signals for ES cycles:
#  - F := esselloff volume (FUND + TREND)
#  - b := synchronization from hittingEs counts
#  - sigma from price returns

build_signals_es_for_era <- function(e, r, a,
                                     tsprices,
                                     tsFUNDesselloffvolume,
                                     tsTRENDesselloffvolume,
                                     tsFUNDhittinges,
                                     tsTRENDhittinges,
                                     w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200) {
  col <- era_col_idx(e, r, a, nRuns, nAssets)
  price <- as.numeric(tsprices[[col]])
  Tlen  <- length(price)
  rts   <- c(NA_real_, diff(base::log(price)))
  sigma <- roll_sd(rts, w_sigma)

  # ES forced-liquidations flow (volume)
  F <- as.numeric(tsFUNDesselloffvolume[[col]]) +
       as.numeric(tsTRENDesselloffvolume[[col]])

  # Synchronization proxy b_t from "hittingEs" counts
  hit_es <- as.numeric(tsFUNDhittinges[[col]]) +
            as.numeric(tsTRENDhittinges[[col]])
  b <- pmin(1, hit_es / (N_FUND + N_TREND))

  tibble(
    t = seq_len(Tlen),
    price = price,
    r = rts,
    sigma = sigma,
    sigma_base = TTR::EMA(sigma, n = ema_sigma_L),  # Slow baseline (EMA) to detect regime shifts vs noise
    F = F,
    F_base = TTR::EMA(F, n = ema_F_L),
    b = b
  )
}


###################################################################
#                                                                 #
#                   DETECTOR WITH HYSTERESIS                      #
#                                                                 #
###################################################################

# Core detector:
# Implements the state machine with hysteresis and an "OFF valley" to separate close episodes.
# Signals expected:
#   - r: log-returns
#   - sigma: rolling volatility (same window you use for VaR/ES if you want consistency)
#   - sigma_base: slow baseline (EMA) for sigma
#   - F: forced selloffs flow (VaR or ES depending on caller)
#   - F_base: slow baseline (EMA) for F
#   - b: synchronization proxy (fraction at limit; or normalized counts)
# All component scores S^· are bounded in [0,1], so the composite C_t in [0,1].
#
# NOTE (change): The start condition NO LONGER includes the directional
# coherence gate (formerly "dir_ok"). Starts are decided solely by the
# composite score + minimum component levels + refractory period.

detect_cycles_core <- function(signals,
                               # ---- component weights (sum to 1)
                               w_F  = 0.50,  # forced selloffs (primary driver)
                               w_sig= 0.30,  # volatility pressure
                               w_b  = 0.15,  # synchronization (fraction at limit)
                               w_r  = 0.05,  # absolute-return shock (light touch)
                               # ---- composite thresholds & hysteresis windows
                               theta_hi = 0.60,  # high threshold to start a cycle (on [0,1] scale)
                               theta_lo = 0.30,  # low threshold to end (classic path)
                               theta_off = 0.25, # "OFF valley" for rapid extinguish
                               m = 4,            # consecutive ticks to confirm start
                               k = 7,            # consecutive ticks to confirm end
                               kprime = 5,       # #ticks with Δσ<0 within last k
                               W_end = 60,       # local baseline window for ending
                               g = 10,           # OFF valley consecutive ticks
                               tau_ref = 7,      # refractory period after an end
                               # ---- bounded-score construction params
                               cal_frac = 0.40,  # fraction of initial sample for calibration
                               L_F_short = 8,    # short EMA window for F (reactive)
                               L_p = 20,         # EMA window for occurrence p_t = 1{F>0}
                               beta_occ = 0.30,  # weight of occurrence inside S^F
                               L_b = 14,         # EMA smoothing for b (already 0..1)
                               # start-condition minimum component levels (on [0,1])
                               start_min_S_F = 0.20,
                               start_min_S_sig = 0.20,
                               # ridge settings to avoid division by ~0
                               ridge_q_F = 0.10,     # quantile for λ_F over calibration slice
                               ridge_q_sig = 0.10,   # quantile for λ_σ over calibration slice
                               eps_floor = 1e-12     # absolute floor for ridges/denoms
) {
  # ---------- helpers ---------- #
  clip01 <- function(x) pmin(1, pmax(0, x))
  roll_med <- function(x, w) zoo::rollapply(x, w, median, align = "right", fill = NA, na.rm = TRUE)
  roll_all_ge <- function(x, t, m, thr) if (t - m + 1 < 1) FALSE else all(x[(t-m+1):t] >= thr, na.rm = TRUE)
  roll_all_le <- function(x, t, k, thr) if (t - k + 1 < 1) FALSE else all(x[(t-k+1):t] <= thr, na.rm = TRUE)
  count_recent <- function(cond, t, L) if (t - L + 1 < 1) 0L else sum(cond[(t-L+1):t], na.rm = TRUE)

  # ---------- unpack signals ---------- #
  r      <- signals$r
  sigma  <- signals$sigma
  sbase  <- signals$sigma_base
  Fflow  <- signals$F
  Fbase  <- signals$F_base
  b_frac <- signals$b

  Tlen <- NROW(sigma)
  cal_end <- max(10, floor(cal_frac * Tlen))

  # ---------- ridges (calibrated on initial quiet slice) ---------- #
  # Prevents division by ~0 when baselines are near zero.
  lambda_F   <- max(stats::quantile(Fflow[seq_len(cal_end)], probs = ridge_q_F, na.rm = TRUE), eps_floor)
  lambda_sig <- max(stats::quantile(sigma[seq_len(cal_end)],  probs = ridge_q_sig, na.rm = TRUE), eps_floor)

  # ---------- component scores S^· in [0,1] ---------- #
  # Forced selloffs: relative lift of a short EMA vs slow baseline, plus an occurrence term.
  F_short <- TTR::EMA(Fflow, n = L_F_short)
  p_occ   <- TTR::EMA(as.numeric(Fflow > 0), n = L_p)
  S_F_rel <- pmax(0, F_short - Fbase) / (Fbase + lambda_F)
  S_F     <- clip01(S_F_rel + beta_occ * p_occ)

  # Synchronization: smoothed fraction at risk limit (already 0..1).
  S_b <- clip01(TTR::EMA(b_frac, n = L_b))

  # Volatility pressure: relative to slow baseline with ridge, capped at 1.
  S_sig <- clip01(pmax(0, sigma - sbase) / (sbase + lambda_sig))

  # Absolute-return shock: scale by a high quantile on calibration slice, capped at 1.
  abs_r <- abs(r)
  q90_r <- stats::quantile(abs_r[seq_len(cal_end)], probs = 0.90, na.rm = TRUE)
  S_r   <- clip01(abs_r / (q90_r + eps_floor))

  # Composite score on a bounded scale.
  C <- w_F*S_F + w_sig*S_sig + w_b*S_b + w_r*S_r

  # ---------- auxiliary series for state conditions ---------- #
  d_sigma <- c(0, diff(sigma))   # keep for ending logic

  # "Low F" threshold from calibration slice (10th percentile).
  # With zero-inflation this is typically 0, which is exactly what we want.
  eps_F <- stats::quantile(Fflow[seq_len(cal_end)], probs = 0.10, na.rm = TRUE)

  # Local median baseline for ending logic (follows σ quicker than EMA to avoid aftershocks).
  sigma_end_base <- roll_med(sigma, W_end)

  # ---------- main state machine ---------- #
  in_cycle <- FALSE
  last_end <- -Inf
  off_run  <- 0L
  starts   <- integer(0)
  ends     <- integer(0)

  for (t in seq_len(Tlen)) {
    # -------- START conditions -------- #
    # Require: sustained high composite score; non-trivial σ and F components;
    # and a refractory period from the last end.
    cond_score_hi <- roll_all_ge(C, t, m, theta_hi)
    cond_sigma_up <- is.finite(S_sig[t]) && (S_sig[t] >= start_min_S_sig)
    cond_F_up     <- is.finite(S_F[t])   && (S_F[t]   >= start_min_S_F)
    cond_ref      <- (t - last_end) >= tau_ref

    # NOTE: directional coherence (former "dir_ok") has been removed.
    if (!in_cycle && cond_ref && cond_score_hi && cond_sigma_up && cond_F_up) {
      starts  <- c(starts, t)
      in_cycle <- TRUE
      off_run  <- 0L
    }

    # -------- OFF-valley tracking -------- #
    # If both C_t and raw F stay low for g ticks, consider the cycle extinguished fast.
    if (is.finite(C[t]) && (C[t] <= theta_off) && (Fflow[t] <= eps_F)) {
      off_run <- off_run + 1L
    } else {
      off_run <- 0L
    }

    # -------- END conditions -------- #
    if (in_cycle) {
      # Classic local ending: low score, low selloffs, σ below local baseline and decreasing.
      cond_score_lo  <- roll_all_le(C, t, k, theta_lo)
      cond_F_down    <- count_recent(Fflow <= eps_F, t, k + 2) >= k
      cond_sigma_loc <- count_recent(sigma <= sigma_end_base, t, k) >= (k - 1)
      cond_slope_dn  <- count_recent(d_sigma < 0, t, k) >= kprime

      end_A <- cond_score_lo && cond_F_down && cond_sigma_loc && cond_slope_dn
      end_B <- (off_run >= g)  # OFF-valley path (quick separation from aftershocks)

      if (end_A || end_B) {
        ends     <- c(ends, t)
        in_cycle <- FALSE
        last_end <- t
        off_run  <- 0L
      }
    }
  }
  if (in_cycle) ends <- c(ends, Tlen)

  # Build per-cycle table and attach component/score series for diagnostics.
  out <- tibble::tibble(
    t_start = starts,
    t_end   = ends,
    duration = if (length(starts) == length(ends)) (ends - starts + 1L) else NA_integer_
  )
  attr(out, "score")      <- C
  attr(out, "components") <- tibble::tibble(S_F = S_F, S_sig = S_sig, S_b = S_b, S_r = S_r, C = C)
  out
}



###################################################################
#                                                                 #
#                        ORCHESTRATOR                             #
#                                                                 #
###################################################################

## -------------- VaR cycles across all E/R/A ------------------ ##

# Runs the VaR-cycle detector on every column (one run per column).
# Uses bounded, baseline-relative scoring inside detect_cycles_core.

detect_cycles_var_all <- function(tsprices,
                                  tsFUNDvarselloffvolume,
                                  tsTRENDvarselloffvolume,
                                  tsFUNDhittingvar,
                                  tsTRENDhittingvar,
                                  # volatility and EMA baselines
                                  w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                                  # detector params (passed into detect_cycles_core)
                                  detector_params = list(
                                    # component weights on [0,1] scores
                                    w_F = 0.50, w_sig = 0.30, w_b = 0.15, w_r = 0.05,
                                    # thresholds on [0,1]
                                    theta_hi = 0.60, theta_lo = 0.30, theta_off = 0.25,
                                    # hysteresis windows (unchanged)
                                    m = 4, k = 7, kprime = 5, W_end = 60, g = 10, tau_ref = 7,
                                    # bounded-score construction
                                    cal_frac = 0.40,
                                    L_F_short = 8, L_p = 20, beta_occ = 0.30,
                                    L_b = 14,
                                    start_min_S_F = 0.20, start_min_S_sig = 0.20,
                                    ridge_q_F = 0.10, ridge_q_sig = 0.10, eps_floor = 1e-12
                                  )) {
  per_era <- vector("list", nExp)
  summaries <- list()

  for (e in 1:nExp) {
    per_era[[e]] <- vector("list", nRuns)
    for (r in 1:nRuns) {
      per_era[[e]][[r]] <- vector("list", nAssets)
      for (a in 1:nAssets) {
        sig <- build_signals_var_for_era(
          e, r, a,
          tsprices,
          tsFUNDvarselloffvolume,
          tsTRENDvarselloffvolume,
          tsFUNDhittingvar,
          tsTRENDhittingvar,
          w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L
        )
        # Detect cycles
        det <- do.call(detect_cycles_core, c(list(signals = sig), detector_params))

        # Store full per-run detection table (attrs carry component series)
        per_era[[e]][[r]][[a]] <- det

        # Summaries per run (count and durations)
        summaries[[length(summaries) + 1]] <- tibble(
          experiment = e, run = r, asset = a,
          n_cycles = nrow(det),
          mean_duration = if (nrow(det) > 0) mean(det$duration, na.rm = TRUE) else 0,
          median_duration = if (nrow(det) > 0) median(det$duration, na.rm = TRUE) else 0,
          total_time_in_cycles = if (nrow(det) > 0) sum(det$duration, na.rm = TRUE) else 0
        )
      }
    }
  }

  list(
    per_era_cycles = per_era,    # nested list: [E][R][A] -> tibble(t_start, t_end, duration), attrs with components
    summary = dplyr::bind_rows(summaries)
  )
}


## -------------- ES cycles across all E/R/A ------------------ ##

# Runs the ES-cycle detector on every column (one run per column).

detect_cycles_es_all <- function(tsprices,
                                 tsFUNDesselloffvolume,
                                 tsTRENDesselloffvolume,
                                 tsFUNDhittinges,
                                 tsTRENDhittinges,
                                 w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                                 # detector params (passed into detect_cycles_core)
                                 detector_params = list(
                                   # component weights on [0,1] scores
                                   w_F = 0.50, w_sig = 0.30, w_b = 0.15, w_r = 0.05,
                                   # thresholds on [0,1]
                                   theta_hi = 0.60, theta_lo = 0.30, theta_off = 0.25,
                                   # hysteresis windows (unchanged)
                                   m = 4, k = 7, kprime = 5, W_end = 60, g = 10, tau_ref = 7,
                                   # bounded-score construction
                                   cal_frac = 0.40,
                                   L_F_short = 8, L_p = 20, beta_occ = 0.30,
                                   L_b = 14,
                                   start_min_S_F = 0.20, start_min_S_sig = 0.20,
                                   ridge_q_F = 0.10, ridge_q_sig = 0.10, eps_floor = 1e-12
                                 )) {
  per_era <- vector("list", nExp)
  summaries <- list()

  for (e in 1:nExp) {
    per_era[[e]] <- vector("list", nRuns)
    for (r in 1:nRuns) {
      per_era[[e]][[r]] <- vector("list", nAssets)
      for (a in 1:nAssets) {
        sig <- build_signals_es_for_era(
          e, r, a,
          tsprices,
          tsFUNDesselloffvolume,
          tsTRENDesselloffvolume,
          tsFUNDhittinges,
          tsTRENDhittinges,
          w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L
        )
        # Detect cycles
        det <- do.call(detect_cycles_core, c(list(signals = sig), detector_params))
        per_era[[e]][[r]][[a]] <- det

        # Summaries per run (count and durations)
        summaries[[length(summaries) + 1]] <- tibble(
          experiment = e, run = r, asset = a,
          n_cycles = nrow(det),
          mean_duration = if (nrow(det) > 0) mean(det$duration, na.rm = TRUE) else 0,
          median_duration = if (nrow(det) > 0) median(det$duration, na.rm = TRUE) else 0,
          total_time_in_cycles = if (nrow(det) > 0) sum(det$duration, na.rm = TRUE) else 0
        )
      }
    }
  }

  list(
    per_era_cycles = per_era,
    summary = bind_rows(summaries)
  )
}



###################################################################
#                                                                 #
#           INSPECTION AND VISUALISATION OF RESULTS               #
#                                                                 #
###################################################################

#_________________________________________________________________#
#                                                                 # 
#                         VaR/ES CYCLES                           #
#_________________________________________________________________#
#                                                                 #

# ---------- Helpers to fetch cycle tables ---------- #

get_cycles_for <- function(det_all, e, r, a) {
  # Safely extract the tibble(t_start, t_end, duration) for this (E,R,A)
  det <- det_all$per_era_cycles[[e]][[r]][[a]]
  if (is.null(det)) {
    return(tibble::tibble(t_start = integer(0), t_end = integer(0), duration = integer(0)))
  }
  det
}

# Convenience: return both VaR and ES cycles for (E,R,A)
cycles_info_both <- function(var_all, es_all, e, r, a) {
  list(
    var = get_cycles_for(var_all, e, r, a),
    es  = get_cycles_for(es_all,  e, r, a)
  )
}


#_________________________________________________________________#
#                                                                 # 
#                Inspection of raw time series                    #
#_________________________________________________________________#
#                                                                 #

# ---------- build a boolean mask of "in cycle" over time ---------- #

.incycle_mask_from_det <- function(det, Tlen) {
  mask <- rep(FALSE, Tlen)
  if (nrow(det) > 0) {
    for (i in seq_len(nrow(det))) {
      s <- max(1L, det$t_start[i])
      e <- min(Tlen, det$t_end[i])
      if (is.finite(s) && is.finite(e) && e >= s) mask[s:e] <- TRUE
    }
  }
  mask
}

# ---------- core table builder (shared) ---------- #
.build_inspection_table_core <- function(sig, det) {
  # Pull bounded component scores / composite from detector (exact values used)
  comps <- attr(det, "components")
  # Fallback if attributes are missing (e.g., legacy detector)
  if (is.null(comps)) {
    # Build minimal placeholders to keep table functional
    Tlen <- nrow(sig)
    comps <- tibble::tibble(
      S_F = rep(NA_real_, Tlen),
      S_sig = rep(NA_real_, Tlen),
      S_b = rep(NA_real_, Tlen),
      S_r = rep(NA_real_, Tlen),
      C = { sc <- attr(det, "score"); if (is.null(sc)) rep(NA_real_, Tlen) else sc }
    )
  }

  Tlen <- nrow(sig)
  in_cycle <- .incycle_mask_from_det(det, Tlen)

  tibble::tibble(
    t      = sig$t,
    F      = sig$F,
    b      = sig$b,
    sigma  = sig$sigma,
    abs_r  = abs(sig$r),
    C      = comps$C,
    in_cycle = in_cycle
  )
}

# ---------- VaR variant ---------- #

inspection_table_var <- function(e, r, a,
                                 det_all_var,
                                 w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                                 t_from = NULL, t_to = NULL) {
  det <- get_cycles_for(det_all_var, e, r, a)
  # rebuild signals to expose raw components for the table
  sig <- build_signals_var_for_era(
    e, r, a, tsprices,
    tsFUNDvarselloffvolume, tsTRENDvarselloffvolume,
    tsFUNDhittingvar, tsTRENDhittingvar,
    w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L
  )
  tbl <- .build_inspection_table_core(sig, det)

  # clip to requested range
  if (is.null(t_from)) t_from <- min(tbl$t, na.rm = TRUE)
  if (is.null(t_to))   t_to   <- max(tbl$t, na.rm = TRUE)
  dplyr::filter(tbl, t >= t_from, t <= t_to)
}

# ---------- ES variant ---------- #

inspection_table_es <- function(e, r, a,
                                det_all_es,
                                w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                                t_from = NULL, t_to = NULL) {
  det <- get_cycles_for(det_all_es, e, r, a)
  sig <- build_signals_es_for_era(
    e, r, a, tsprices,
    tsFUNDesselloffvolume, tsTRENDesselloffvolume,
    tsFUNDhittinges, tsTRENDhittinges,
    w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L
  )
  tbl <- .build_inspection_table_core(sig, det)

  if (is.null(t_from)) t_from <- min(tbl$t, na.rm = TRUE)
  if (is.null(t_to))   t_to   <- max(tbl$t, na.rm = TRUE)
  dplyr::filter(tbl, t >= t_from, t <= t_to)
}


#_________________________________________________________________#
#                                                                 # 
#              Inspection of S_* score time series                #
#_________________________________________________________________#
#                                                                 #

# ---------- core builder: returns S_* scores + composite + in_cycle ---------- #

.build_inspection_scores_table_core <- function(sig, det) {
  comps <- attr(det, "components")
  if (is.null(comps)) {
    stop("No bounded components found in 'det'. Make sure you're using the bounded detect_cycles_core that attaches attr(det, 'components').")
  }
  Tlen <- nrow(sig)
  in_cycle <- .incycle_mask_from_det(det, Tlen)

  tibble::tibble(
    t       = sig$t,
    S_F     = comps$S_F,
    S_b     = comps$S_b,
    S_sig   = comps$S_sig,
    S_r     = comps$S_r,
    C       = comps$C,
    in_cycle = in_cycle
  )
}

# ---------- VaR: inspection table with S_* scores ---------- #

inspection_table_var_scores <- function(e, r, a,
                                        det_all_var,
                                        w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                                        t_from = NULL, t_to = NULL) {
  det <- get_cycles_for(det_all_var, e, r, a)
  # Rebuild signals to get t index length and for consistency with detector alignment
  sig <- build_signals_var_for_era(
    e, r, a,
    tsprices,
    tsFUNDvarselloffvolume, tsTRENDvarselloffvolume,
    tsFUNDhittingvar, tsTRENDhittingvar,
    w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L
  )
  tbl <- .build_inspection_scores_table_core(sig, det)
  if (is.null(t_from)) t_from <- min(tbl$t, na.rm = TRUE)
  if (is.null(t_to))   t_to   <- max(tbl$t, na.rm = TRUE)
  dplyr::filter(tbl, t >= t_from, t <= t_to)
}

# ---------- ES: inspection table with S_* scores ---------- #

inspection_table_es_scores <- function(e, r, a,
                                       det_all_es,
                                       w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                                       t_from = NULL, t_to = NULL) {
  det <- get_cycles_for(det_all_es, e, r, a)
  sig <- build_signals_es_for_era(
    e, r, a,
    tsprices,
    tsFUNDesselloffvolume, tsTRENDesselloffvolume,
    tsFUNDhittinges, tsTRENDhittinges,
    w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L
  )
  tbl <- .build_inspection_scores_table_core(sig, det)
  if (is.null(t_from)) t_from <- min(tbl$t, na.rm = TRUE)
  if (is.null(t_to))   t_to   <- max(tbl$t, na.rm = TRUE)
  dplyr::filter(tbl, t >= t_from, t <= t_to)
}



#_________________________________________________________________#
#                                                                 # 
#                Visualisation of time series                     #
#                                                                 #
#_________________________________________________________________#

# ---------- helper to build shading rectangles from det & range ---------- #

.episode_rects <- function(det, t_from, t_to) {
  if (nrow(det) == 0) return(tibble::tibble(xmin = numeric(0), xmax = numeric(0)))
  dplyr::transmute(
    det,
    xmin = pmax(t_start, t_from),
    xmax = pmin(t_end,   t_to)
  ) |>
    dplyr::filter(xmax >= xmin)
}

# ---------- core plotting function (shared) ---------- #

.plot_inspection_core <- function(tbl, det, title, t_from, t_to) {
  # long format for faceting
  plot_df <- tidyr::pivot_longer(
    tbl,
    cols = c(F, b, sigma, abs_r, C),
    names_to = "series",
    values_to = "value"
  )

  rects <- .episode_rects(det, t_from, t_to)

  ggplot2::ggplot(plot_df, ggplot2::aes(x = t, y = value)) +
    # cycle shading across all facets
    { if (nrow(rects) > 0)
        ggplot2::geom_rect(data = rects,
                           ggplot2::aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
                           inherit.aes = FALSE, alpha = 0.12)
      else NULL } +
    ggplot2::geom_line(linewidth = 0.35) +
    ggplot2::facet_wrap(~ series, ncol = 1, scales = "free_y",
                        labeller = ggplot2::labeller(series = c(
                          F = "Selloff volume (forced)",
                          b = "Fraction hitting limit (b)",
                          sigma = "Volatility (σ)",
                          abs_r = "Absolute return |r|",
                          C = "Composite C_t"
                        ))) +
    ggplot2::labs(title = title, x = "tick", y = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "bold"),
      panel.spacing.y = grid::unit(6, "pt"),
      plot.title = ggplot2::element_text(face = "bold")
    )
}

# ---------- VaR plot ---------- #

plot_inspection_var <- function(e, r, a,
                                det_all_var,
                                w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                                t_from = NULL, t_to = NULL) {
  det <- get_cycles_for(det_all_var, e, r, a)
  tbl <- inspection_table_var(e, r, a, det_all_var,
                              w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L,
                              t_from = t_from, t_to = t_to)
  if (is.null(t_from)) t_from <- min(tbl$t, na.rm = TRUE)
  if (is.null(t_to))   t_to   <- max(tbl$t, na.rm = TRUE)
  .plot_inspection_core(tbl, det, sprintf("VaR inspection E%d R%d A%d", e, r, a), t_from, t_to)
}

# ---------- ES plot ---------- #

plot_inspection_es <- function(e, r, a,
                               det_all_es,
                               w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                               t_from = NULL, t_to = NULL) {
  det <- get_cycles_for(det_all_es, e, r, a)
  tbl <- inspection_table_es(e, r, a, det_all_es,
                             w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L,
                             t_from = t_from, t_to = t_to)
  if (is.null(t_from)) t_from <- min(tbl$t, na.rm = TRUE)
  if (is.null(t_to))   t_to   <- max(tbl$t, na.rm = TRUE)
  .plot_inspection_core(tbl, det, sprintf("ES inspection E%d R%d A%d", e, r, a), t_from, t_to)
}



#_________________________________________________________________#
#                                                                 # 
#                         EXAMPLE OF USE                          #
#_________________________________________________________________#
#                                                                 #

# After running the detectors:

var_results <- detect_cycles_var_all(tsprices, tsFUNDvarselloffvolume, tsTRENDvarselloffvolume,
                                     tsFUNDhittingvar, tsTRENDhittingvar)
es_results  <- detect_cycles_es_all(tsprices, tsFUNDesselloffvolume, tsTRENDesselloffvolume,
                                    tsFUNDhittinges, tsTRENDhittinges)

e_sel <- 1; r_sel <- 13; a_sel <- 1
t0 <- 1;  t1 <- 4000

# 1) Cycle info (tables)
cycles_info_both(var_results, es_results, e = e_sel, r = r_sel, a = a_sel)

# 2) Inspection table over a time window
# Raw time series
tbl_var <- inspection_table_var(e_sel, r_sel, a_sel, var_results, t_from = t0, t_to = t1)
#tbl_es  <- inspection_table_es(e_sel, r_sel, a_sel, es_results,  t_from = t0, t_to = t1)

# S_* score time series
scores_var <- inspection_table_var_scores(e_sel, r_sel, a_sel, var_results, t_from = t0, t_to = t1)
#scores_es  <- inspection_table_es_scores(e_sel, r_sel, a_sel, var_results, t_from = t0, t_to = t1)

# 3) Plots (stacked panels with cycle shading)
plot_inspection_var(e_sel, r_sel, a_sel, var_results, t_from = t0, t_to = t1)
#plot_inspection_es(e_sel, r_sel, a_sel, var_results, t_from = t0, t_to = t1)



#_________________________________________________________________#
#                                                                 # 
#                     CHECK ENTRY CONDITIONS                      #
#                                                                 #
#_________________________________________________________________#
#                                                                 #

# Updated to match detector WITHOUT directional gate
diagnose_var_start <- function(e, r, a, det_all_var,
                               t_from, t_to,
                               w_sigma = 20, ema_sigma_L = 400, ema_F_L = 200,
                               # must match your detect_cycles_core params
                               theta_hi = 0.60, m = 4, tau_ref = 7,
                               start_min_S_F = 0.20, start_min_S_sig = 0.20) {

  det <- get_cycles_for(det_all_var, e, r, a)

  sig <- build_signals_var_for_era(
    e, r, a, tsprices,
    tsFUNDvarselloffvolume, tsTRENDvarselloffvolume,
    tsFUNDhittingvar, tsTRENDhittingvar,
    w_sigma = w_sigma, ema_sigma_L = ema_sigma_L, ema_F_L = ema_F_L
  )

  comps <- attr(det, "components")
  stopifnot(!is.null(comps))

  # refractory: last end before each t
  last_end_before_t <- rep(-Inf, nrow(sig))
  if (nrow(det) > 0) {
    ends <- det$t_end
    for (i in seq_along(ends)) {
      last_end_before_t[(ends[i] + 1):nrow(sig)] <- ends[i]
    }
  }

  # rolling helper
  roll_all_ge <- function(x, t, m, thr) if (t - m + 1 < 1) FALSE else all(x[(t-m+1):t] >= thr, na.rm = TRUE)

  keep <- (sig$t >= t_from & sig$t <= t_to)
  out <- tibble::tibble(
    t = sig$t[keep],
    S_F = comps$S_F[keep],
    S_sig = comps$S_sig[keep],
    C = comps$C[keep]
  )

  # compute gates over full series, then subset
  cond_score_hi <- vapply(seq_len(nrow(sig)), function(t) roll_all_ge(attr(det, "components")$C, t, m, theta_hi), TRUE)
  cond_sigma_up <- comps$S_sig >= start_min_S_sig
  cond_F_up     <- comps$S_F   >= start_min_S_F
  cond_ref      <- (seq_len(nrow(sig)) - last_end_before_t) >= tau_ref

  out$score_hi  <- cond_score_hi[keep]
  out$sig_up    <- cond_sigma_up[keep]
  out$F_up      <- cond_F_up[keep]
  out$ref_ok    <- cond_ref[keep]
  out$all_ok    <- out$score_hi & out$sig_up & out$F_up & out$ref_ok
  out
}


###################### USAGE ##########################

diag <- diagnose_var_start(e_sel, r_sel, a_sel, var_results, t_from = t0, t_to = t1)
print(diag)
