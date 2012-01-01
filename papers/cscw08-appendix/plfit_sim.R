# Copyright (c) 2008 Rick Wash <rwash@umich.edu>
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# plfit_sim.R
# Rick Wash <rwash@umich.edu>
#
# Calculates the powerlaw fit and the inter-user agreement for the monte-carlo simulation data

run_condition <- function(con, condition="onsite") {
  real_ids <- sqlQuery(con, paste("select distinct real_deliciousID from mc_info where user_type = \"", condition, "\"", sep=""))$real_deliciousID
  out <- data.frame(alpha=numeric(), delta=numeric(), KS=numeric())
  for (real_id in real_ids) {
    cat("Doing ", real_id, "...\n")
    real_data <- site_data(con, real_id)
    real_fit <- summary(plm(real_data$tag, xmin=1))
    # Get fake ids
    fake_ids <- sqlQuery(con, paste("select distinct fake_deliciousID from mc_info where user_type = \"", condition, "\" and real_deliciousID = \"", real_id, "\"", sep=""))$fake_deliciousID
    info <- sapply(fake_ids, function(fake_id) { plfit_sim(fake_id, real_fit$fit$alpha, con)})
    out <- rbind(out, t(info))
  }
  out
}

plfit_sim <- function(fake_id, real_alpha, con, type) {
  cat("  - Doing fake id ", fake_id, "...")
  fake_data <- site_data(con, fake_id, "mc")
  N <- nlevels(fake_data$tag)
  cat(paste(" fit(", N, ")...", sep=""))
  basic_fit <- plm(fake_data$tag, xmin=1)
  cat(" summary...")
  fake_fit <- summary.plm(basic_fit, xmin=1)
  cat("\n")
  delta <- abs(real_alpha - fake_fit$fit$alpha)
  KS <- fake_fit$KS
  out <- c(as.character(fake_id), fake_fit$fit$alpha, delta, KS, type)
  names(out) <- list("id", "alpha", "delta", "KS", "type")
  out
}

calc_plfit <- function(con) {
  real_ids <- sqlQuery(con, "select distinct real_deliciousID from mc_info")$real_deliciousID
  out <- data.frame(id=character(), alpha=numeric(), delta=numeric(), KS=numeric())
  for (real_id in real_ids) {
    cat("Doing ", real_id, "...\n")
    real_data <- site_data(con, real_id)
    real_fit <- summary(plm(real_data$tag, xmin=1))
    real_alpha = real_fit$fit$alpha
    temp <- c(real_id, real_alpha, 0, real_fit$KS, "Real World")
    names(temp) <- list("id", "alpha", "delta", "KS", "type")
    out <- rbind(out, t(temp))
    # Get fake ids
    id_list <- sqlQuery(con, paste("select distinct fake_deliciousID, user_type from mc_info WHERE real_deliciousID = \"", real_id, "\"", sep=""))
    fake_ids <- id_list$fake_deliciousID
    info <- sapply(fake_ids, function(fake_id) {
      type = id_list$user_type[which(fake_ids == fake_id)];
      plfit_sim(fake_id, real_alpha, con, type)})
    out <- rbind(out, t(info))
  }
  out
}


plfit_sim_nosum <- function(fake_id, con, type) {
  cat("  - Doing fake id ", fake_id, "...")
  fake_data <- site_data(con, fake_id, "mc")
  N <- nlevels(fake_data$tag)
  cat(paste(" fit(", N, ")...", sep=""))
  fake_fit <- plm(fake_data$tag, xmin=1)
#  cat(" summary...")
#  fake_fit <- summary.plm(basic_fit, xmin=1)
  cat("\n")
#  delta <- abs(real_alpha - fake_fit$fit$alpha)
 # KS <- fake_fit$KS
  out <- c(as.character(fake_id), fake_fit$alpha, type)
  names(out) <- list("id", "alpha", "type")
  out
}

calc_plfit_nosum <- function(con) {
  real_ids <- sqlQuery(con, "select distinct real_deliciousID from mc_info")$real_deliciousID
  out <- data.frame(id=character(), alpha=numeric(), type=character())
  for (real_id in real_ids) {
    cat("Doing ", real_id, "...\n")
    real_data <- site_data(con, real_id)
#    real_fit <- summary(plm(real_data$tag, xmin=1))
    real_fit <- plm(real_data$tag, xmin=1)
    real_alpha = real_fit$alpha
    temp <- c(real_id, real_alpha, "Real World")
    names(temp) <- list("id", "alpha", "type")
    out <- rbind(out, t(temp))
    # Get fake ids
    id_list <- sqlQuery(con, paste("select distinct fake_deliciousID, user_type from mc_info WHERE real_deliciousID = \"", real_id, "\"", sep=""))
    fake_ids <- id_list$fake_deliciousID
    info <- sapply(fake_ids, function(fake_id) {
      type = id_list$user_type[which(fake_ids == fake_id)];
      plfit_sim_nosum(fake_id, con, type)})
    out <- rbind(out, t(info))
  }
  out
}

plfit_site <- function(con, id, prefix, epsilon=0.1) {
  cat("- Doing  id ", id, "...")
  data <- site_data(con, id, prefix)
  N <- nlevels(data$tag)
  cat(paste("(", N, ")... fit...", sep=""))
  basic_fit <- plm(data$tag, xmin=1)
  cat(" summary...")
  fit <- summary.plm(basic_fit, epsilon=epsilon)
  cat("\n")
  KS <- fit$KS
  out <- list(as.character(id), fit$fit$alpha, KS, fit$p)
  names(out) <- c("id", "alpha", "KS", "p")
  out
}

plfit <- function(con, condition = c("Real World", "urn", "user", "recommended", "unbiased", "onsite"), id_list = NULL, prefix="jan2007" , epsilon=0.1) {
  condition <- match.arg(condition)
  if (is.null(id_list)) {
    if (condition == "Real World") {
      id_list <- sqlQuery(con, "select distinct real_deliciousID from mc_info")$real_deliciousID
      prefix <- "jan2007"
    } else {
      id_list <- sqlQuery(con, paste("select distinct fake_deliciousID from mc_info where user_type = \"", condition, "\"", sep=""))$fake_deliciousID
      prefix <- "mc"
    }
  }
  ids <- character()
  alphas <- numeric()
  KSs <- numeric()
  ps <- numeric()
  for (id in id_list) {
    temp <- plfit_site(con, id, prefix, epsilon=epsilon)
    ids <- c(ids, temp[['id']])
    alphas <- c(alphas, temp[['alpha']])
    KSs <- c(KSs, temp[['KS']])
    ps <- c(ps, temp[['p']])
  }
  out <- data.frame(id=ids, alpha=alphas, KS=KSs, p=ps)
  out
}

run_all_plfit <- function(con, conditions = c("Real World", "urn", "user", "recommended", "unbiased", "onsite")) {
  fit_real <- plfit(con, "Real World", epsilon=0.05)
  fit_urn <- plfit(con, "urn", epsilon=0.05)
  fit_user <- plfit(con, "user", epsilon=0.05)
  fit_recommended <- plfit(con, "recommended", epsilon=0.05)
  fit_unbiased <- plfit(con, "unbiased", epsilon=0.05)
  fit_onsite <- plfit(con, "onsite", epsilon=0.05)
}

combine_fits <- function(con, condition, fit.real=fit_real, fit.cond=NULL) {
  if (is.null(fit.cond)) {
    fit.cond <- get(paste("fit_", condition, sep=""))
  }
  info <- sqlQuery(con, paste("select real_deliciousID, fake_deliciousID from mc_info where user_type = \"", condition, "\"", sep=""))
  real_ids <- sapply(fit.cond$id, function(id) { info$real_deliciousID[which(info$fake_deliciousID == id)]})
  real_rows <- sapply(real_ids, function(id) { which(fit.real$id == id) })
  out <- data.frame(fit.cond, real_id = fit.real$id[real_rows], real.alpha = fit.real$alpha[real_rows], real.KS = fit.real$KS[real_rows])
#   for (fake_row in 1:length(fit.cond$id)) {
#     fake_id <- fit.cond$id[fake_row]
#     real_id <- info$real_deliciousID[which(info$fake_deliciousID == fake_id)]
#     real_row <- which(fit.real$id == real_id)
#     data <- c(fake_id, real_id, fit.cond$alpha[fake_row], fit.cond$KS[fake_row], fit.real$alpha[real_row], fit.real$KS[real_row])
#   }
  out
}

do_cfit_tests <- function(conditions = c("unbiased", "urn", "user", "recommended", "onsite"), parameter = c("alpha", "KS"), paired=FALSE) {
  parameter <- match.arg(parameter)
  for (cond in conditions) {
    cat("**** Test for", cond, "on", parameter, "\n\n")
    cfit <- get(paste("cfit_", cond, sep=""))
    out <- wilcox.test(x=cfit[[parameter]], y=cfit[[paste("real.", parameter, sep="")]], paired=paired)
    print(out)    
  }
}

cfit_numbers <- function(conditions = c("unbiased", "urn", "user", "recommended", "onsite")) {
  sapply(conditions, function(cond) {
    cfit <- get(paste("cfit_", cond, sep=""))
    out <- c(mean(cfit$alpha), mean(abs(cfit$alpha - cfit$real.alpha)), mean(cfit$KS))
    names(out) <- c("Alpha", "Delta", "KS")
    out
  })
}

plot_site_data <- function(con, id, prefix="jan2007", type=id) {
  data <- site_data(con, id, prefix)
  info <- tapply(data$tag, data$tag, length)
  info <- sort(info, dec=T)
  df <- data.frame(x=1:length(info), y=info, id=rep(type, length(info)))
  df
}

plot_sites <- function(con, real_id, fake_id, conditions = c("unbiased", "urn", "user", "recommended", "onsite")) {
  real_data <- plot_site_data(con, real_id, type="Real World")
  out <- real_data
  for (cond in conditions) {
    id <- sqlQuery(con, paste("select fake_deliciousID from mc_info where real_deliciousID = \"", real_id, "\" and fake_deliciousID >= ", fake_id, " and user_type = \"", cond, "\" limit 1", sep=""))$fake_deliciousID
    fake_data <- plot_site_data(con, id, prefix="mc", type=cond)
    out <- rbind(out, fake_data)
  }
  out
}

ids_for_site <- function(con, real_id, fake_id=NULL, conditions = c("unbiased", "urn", "user", "recommended", "onsite")) {
  ids <- real_id
  if (is.null(fake_id)) { fake_id <- 1}
  for (cond in conditions) {
    id <- sqlQuery(con, paste("select fake_deliciousID from mc_info where real_deliciousID = \"", real_id, "\" and fake_deliciousID >= ", fake_id, " and user_type = \"", cond, "\" limit 1", sep=""))$fake_deliciousID
    ids <- c(ids, id)
  }
  data.frame(id=ids, condition = c("Real World", conditions), prefix=c("jan2007", rep("mc", length(conditions))))
}

plot_plm_sites <- function(con, real_id, fake_id=NULL, conditions = c("unbiased", "urn", "user", "recommended", "onsite")) {
  real_data <- site_data(con, real_id)
  real_fit <- plm(real_data)
  for (cond in conditions) {
    id <- sqlQuery(con, paste("select fake_deliciousID from mc_info where real_deliciousID = \"", real_id, "\" and fake_deliciousID >= ", fake_id, " and user_type = \"", cond, "\" limit 1", sep=""))$fake_deliciousID
  }
}

plot_site <- function(con, id, condition, prefix, split=c(1,1,3,2), ...) {
  data <- site_data(con, id, prefix)
  fit <- plm(data$tag, xmin=1)
  p <- plot(fit, type=c("p", "l"), distribute.type=T, cex=2, main=paste(condition), col=c("#0080ff", "black"), xlab="Tag Index i", ylab="Tags with index > i", scales=list(x=list(tick.number=4, log=T), y=list(log=T)), ...)
  print(p, split=split, newpage=F)
}

plot_sites <- function(con, real_id, fake_id=NULL, conditions=c("unbiased", "urn", "user", "recommended", "onsite"), names=c("Real World", "Zipf", "Imitiation-Urn", "Organizing", "Imitation-Popular", "Imitation-Random"), ...) {
  id_list <- ids_for_site(con, real_id, fake_id, conditions)
  if (is.null(names)) { names <- id_list$condition }
  for (i in 1:length(id_list$id)) {
    split <- c(((i-1) %% 3) + 1, ((i-1) %/% 3) + 1, 3, 2)
    plot_site(con, id_list[i,1], names[i], id_list[i,3], split=split, ...)
  }
}

plot_all_sites <- function(con, ids, names=NULL) {
  for (id in ids) {
    cat("Doing ", id, "\n")
    trellis.device(device="pdf", file=paste(id, ".pdf", sep=""), width=12, height=8)
    plot_sites(con, id, names=names)
    dev.off()
  }
}

test_kss <- function(conditions = c("unbiased", "urn", "user", "recommended", "onsite"), paired=T, big=F, p.adjust.method = p.adjust.methods) {
  match.arg(p.adjust.method)
  if (paired && big) {
    error("Cannot do paired tests with full delicious dataset")
  }
  p.vals <- c()
  for (cond in conditions) {
    cfit <- get(paste("cfit_", cond, sep=""))
    real_ks <- if (big) real_fits$KS else cfit$real.KS
    test <- wilcox.test(cfit$KS, real_ks, paired=paired)
    np <- names(p.vals)
    p.vals <- c(p.vals, test$p.value)
    names(p.vals) <- c(np, cond)
  }
  adj.p <-  p.adjust(p.vals, p.adjust.method)
  adj.p
}

test_kss.t <- function(conditions = c("unbiased", "urn", "user", "recommended", "onsite"), paired=T, big=F, p.adjust.method = p.adjust.methods) {
  p.adjust.method <- match.arg(p.adjust.method)
  if (paired && big) {
    error("Cannot do paired tests with full delicious dataset")
  }
  p.vals <- c()
  for (cond in conditions) {
    cfit <- get(paste("cfit_", cond, sep=""))
    real_ks <- if (big) real_fits$KS else cfit$real.KS
    test <- t.test(cfit$KS, real_ks, paired=paired)
    np <- names(p.vals)
    p.vals <- c(p.vals, test$p.value)
    names(p.vals) <- c(np, cond)
  }
  adj.p <-  p.adjust(p.vals, p.adjust.method)
  adj.p
}

test_iua <- function(conditions = c("unbiased", "urn", "user", "recommended", "onsite"), big=F, paired=T, p.adjust.method = p.adjust.methods) {
  p.adjust.method <- match.arg(p.adjust.method)
  if (paired && big) {
    error("Cannot do paired tests with full delicious dataset")
  }
  p.vals <- c()
  for (cond in conditions) {
    info <- get(paste("iua_", cond, sep=""))
    c_iua <- info$cond.iua
    real_iua <- if (big) real_iua_big$Mean else info$real.iua
    test <- wilcox.test(c_iua, real_iua, paired=paired)
    np <- names(p.vals)
    p.vals <- c(p.vals, test$p.value)
    names(p.vals) <- c(np, cond)
  }
  adj.p <-  p.adjust(p.vals, p.adjust.method)
  adj.p
}

test_iua.t <- function(conditions = c("unbiased", "urn", "user", "recommended", "onsite"), big=F, p.adjust.method = p.adjust.methods) {
  p.adjust.method <- match.arg(p.adjust.method)
  p.vals <- c()
  for (cond in conditions) {
    c_iua <- subset(iua_sim, type==cond)$Mean
    real_iua <- if (big) real_iua_big$Mean else iua_real_small$mean
    test <- t.test(c_iua, real_iua, paired=F)
    np <- names(p.vals)
    p.vals <- c(p.vals, test$p.value)
    names(p.vals) <- c(np, cond)
  }
  adj.p <-  p.adjust(p.vals, p.adjust.method)
  adj.p
}

run_levene_tests <- function(conditions = c("unbiased", "urn", "user", "recommended", "onsite")) {
  out <- lapply(conditions, function(cond) {
    cfit <- get(paste("cfit_", cond, sep=""))
    temp <- melt(cfit, measure.var = c("KS", "real.KS"))
    levene.test(temp$value, temp$variable)
  })
  names(out) <- conditions
  out
}

run_levene_tests_iua <- function(conditions = c("unbiased", "urn", "user", "recommended", "onsite")) {
  out <- lapply(conditions, function(cond) {
    c_iua <- subset(iua_sim, type==cond)$Mean
    real_iua <- iua_real_small$mean
    df <- data.frame(cond = c_iua, real = real_iua)
    temp <- melt(df, measure.var = c("cond", "real"))
    levene.test(temp$value, temp$variable)
  })
  names(out) <- conditions
  out
}

test_kss_subset <- function(sites=30, conditions = c("unbiased", "urn", "user", "recommended", "onsite"), paired=T, big=F, p.adjust.method = p.adjust.methods) {
  match.arg(p.adjust.method)
  if (paired && big) {
    error("Cannot do paired tests with full delicious dataset")
  }
  p.vals <- c()
  for (cond in conditions) {
    cfit <- get(paste("cfit_", cond, sep=""))
    real_ks <- if (big) real_fits$KS else cfit$real.KS
    real_ids <- sample(levels(cfit$real_id), sites)
    cfit_kss <- subset(cfit, real_id %in% real_ids, select=c("KS"))$KS
    real_ks <- subset(cfit, real_id %in% real_ids, select=c("real.KS"))$real.KS
    test <- wilcox.test(cfit_kss, real_ks, paired=paired)
    np <- names(p.vals)
    p.vals <- c(p.vals, test$p.value)
    names(p.vals) <- c(np, cond)
  }
  adj.p <-  p.adjust(p.vals, p.adjust.method)
  adj.p
}

test_kss_subset.t <- function(sites=30, conditions = c("unbiased", "urn", "user", "recommended", "onsite"), paired=T, big=F, p.adjust.method = p.adjust.methods) {
  match.arg(p.adjust.method)
  if (paired && big) {
    error("Cannot do paired tests with full delicious dataset")
  }
  p.vals <- c()
  for (cond in conditions) {
    cfit <- get(paste("cfit_", cond, sep=""))
    real_ks <- if (big) real_fits$KS else cfit$real.KS
    real_ids <- sample(levels(cfit$real_id), sites)
    cfit_kss <- subset(cfit, real_id %in% real_ids, select=c("KS"))$KS
    real_ks <- subset(cfit, real_id %in% real_ids, select=c("real.KS"))$real.KS
    test <- t.test(cfit_kss, real_ks, paired=paired)
    np <- names(p.vals)
    p.vals <- c(p.vals, test$p.value)
    names(p.vals) <- c(np, cond)
  }
  adj.p <-  p.adjust(p.vals, p.adjust.method)
  adj.p
}

combine_iua <- function(con, condition, iua.real=real_iua, iua.cond=NULL) {
  if (is.null(iua.cond)) {
    iua.cond <- subset(iua_sim, type==condition)
  }
  info <- sqlQuery(con, paste("select real_deliciousID, fake_deliciousID from mc_info where user_type = \"", condition, "\"", sep=""))
  real_ids <- sapply(row.names(iua.cond), function(id) {  info$real_deliciousID[which(info$fake_deliciousID == id)]})
  real_rows <- sapply(real_ids, function(id) { which(row.names(iua.real) == id) })
  out <- data.frame(cond.id = row.names(iua.cond), cond.iua = iua.cond$Mean, real.id = row.names(iua.real)[real_rows], real.iua = iua.real$Mean[real_rows])
  out
}
