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
# distcomp.R
# Rick Wash <rwash@umich.edu>
#
# Even when data might look like a powerlaw when graphed, there are a number of other 
# distributions which it could be that all look similar for at least part of the distribution.  
# This code fits the data to seven different distributions, and compares the goodness of fit
# to determine which distribution fits most closely.   The seven distributions are:
#   binomial
#   poisson
#   discrete log-normal
#   negative binomial
#   discrete powerlaw
#   geometric
#   discrete exponential
#
# Mostly based on the following paper:
#  A.ÊClauset, C.ÊR. Shalizi, and M.ÊE.ÊJ. Newman. Power-law distributions in empirical data. Preprint, Jun 2007.  http://arxiv.org/abs/0706.1062v1
#
# One function worth using in this file for the del.icio.us data:
# - check_all_users(db, user_list, type)
#   - type="numtags": Fit distributions to the number of tags per user
#   - type="tagdist": Fit distributions to the number of uses of each tag
#
# Other generally useful functions:
# - compare.dists(data, dists = c("binom", "pois", "disclnorm", "nbinom", "dpowerlaw", "geom", "discexp"))
#   - For a single dataset, fit to all "dists" and then compare the fits
#
# - compare.dists.pair(data, dists)
#   - For a single dataset, fit to two distributions and run a KS test to compare the fits
#
# - dist.fit(dist, data, starting.value, ...)
#   - Fit data to the given distribution using MLE (starting from starting.value)
#   - dist is a string containing the distribution name
#   - Needs either the function d<dist> (e.g. dlnorm) or loglik.<dist> to generate the log 
#     likelihood function



#x Functions for estimating the distribution of tags by a user on a site (#)
get_tags_by_user <- function(db, user, prefix="jun2007") {
  if (prefix == "jun2007")
    user_data <- sqlQuery(db, paste("select u.user, s.position, t.tag from ", prefix, "_user u, ", prefix, "_site s, ", prefix, "_tag t ",
                                  "where u.id = s.user_id and s.id = t.site_id and u.user = '", user, "'", sep=""))
  else
    user_data <- sqlQuery(db, paste("select s.user, s.position, t.tag from ", prefix, "_site s, ", prefix, "_tag t ",
                                  "where s.id = t.site_id and s.user = '", user, "'", sep=""))
  user_data
}

# Functions for estimating the distribution of tags by a user on a site (#)
get_tags_by_site <- function(db, delID, prefix="jun2007") {
  if (prefix == "jun2007")
    site_data <- sqlQuery(db, paste("select u.user, s.position, t.tag from ", prefix, "_user u, ", prefix, "_site s, ", prefix, "_tag t ",
                                  "where u.id = s.user_id and s.id = t.site_id and s.deliciousID = '", delID, "'", sep=""))
  else
    site_data <- sqlQuery(db, paste("select s.user, s.position, t.tag from ", prefix, "_site s, ", prefix, "_tag t ",
                                  "where s.id = t.site_id and s.deliciousID = '", delID, "'", sep=""))
  site_data
}

numtags_by_site <- function(tags) {
  tapply(tags$position, tags$position, length)
}

tag_distribution <- function(tags) {
  tapply(tags$tag, tags$tag, length)
}

check_user <- function(db, user, type = "numtags", dists = c("binom", "pois", "disclnorm", "nbinom", "dpowerlaw", "geom", "discexp"), ...) {
  tags <- get_tags_by_user(db, user, ...)
  if (length(tags$tag) == 0) {
    warning(paste("User", user, "returned zero tags."))
    return(NULL)
  }
  data <- switch(type,
    numtags = numtags_by_site(tags),
    tagdist = tag_distribution(tags),
    stop("Unknown type of distribution to check"))
  if (length(unique(data)) < 2) {
    warning(paste("User", user, "always uses the same number of tags."))
    return(NULL)
  }
  test <- compare.dists(data, dists)
  test
}

check_all_users <- function(db, user_list, type = "numtags", dists = c("binom", "pois", "disclnorm", "nbinom", "dpowerlaw", "geom", "discexp"), ...) {
  # initialize variables
  undet <- 0
  res <- rep(0, length(dists))
  names(res) <- dists
  # Data structure for storing fitted parameters
  data <- list()
  for (d in dists) {
    data[[d]] <- data.frame()
  }
  winners <- character(0) 
 
  # Run the test for each user
  for (u in user_list) {
    cat(paste("Testing user:", u, "\n"))
    test.out <- check_user(db, u, type, dists, ...)
    if (is.null(test.out)) next
    best <- apply(test.out$results, 1, sum)
    bestfits <- which(best == max(best))
    on <- names(winners)
    if (length(bestfits) > 1) {
      undet <- undet + 1
      winners <- c(winners, "Undetermined")
    } else {
      res[bestfits] <- res[bestfits] + 1
      winners <- c(winners, dists[bestfits])
    }
    names(winners) <- c(on, u)
    # Store fitted parameters for future use
    for (d in dists) {
      if (test.out[[d]]$converge)
        data[[d]] <- rbind(data[[d]], data.frame(t(test.out[[d]]$estimate), row.names=u))
    }
  }

  winners <- factor(winners)
  out <- list(dists = dists, results = res, undet = undet, params = data, winners=winners)
  class(out) <- c("check", "list")
  out
}

print.check <- function(x, ...) {
  # Compute overall winner(s)
  best <- which(x$results == max(x$results))

  # Report results to user
  cat(paste("Best fitting distribution(s):", paste(x$dists[best], collapse=", "), "\n  "))

  cat(paste(x$dists, x$results, sep=": ", collapse="\n  "))
  cat("\n")
  cat(paste("  Undetermined:", x$undet, "\n\n"))

  cat("Paremeter Estimates:\n")
  for (d in x$dists) {
    cat(paste("  *", d, "\n"))
    for (n in colnames(x$params[[d]])) {
      par.mean <- mean(x$params[[d]][[n]])
      par.sd <- sd(x$params[[d]][[n]])
      cat(paste("    - ", n, ": ", par.mean, " +- ", par.sd, "\n", sep=""))
    }
  }
  NULL
}


# Functions for estimating which distribution the tags are from
# - Uses maximum likelihood estimation for each candidate distribution
# - Uses a non-nested Kolmogorov-Smirnov (vuong) test for comparing between distributions
# - Uses simple most-wins between pairwise comparisons to determine best fitting distribution


# Return a log-likelihood function.   Generic function
# If a "loglik.<dist>" function exists already, return that.
# if a "d<dist>" probability function exists, use that to construct a log-likelihood function
# Else return an error
loglik <- function(dist, default_data = NULL) {
  if (exists(paste("loglik.", dist, sep=""), mode="function")) {
    return(get(paste("loglik.", dist, sep=""), mode="function"))
  }
  if (exists(paste("d", dist, sep=""))) {
    out <- function(params, data=default_data) {
      do.call(paste("d", dist, sep=""), c(list(x=data, log=T), params))
    }
    return(out)
  }
  stop(paste("Don't know how to produce the log likelihood function for", dist))

}

# Compose a negative log-likelihood function for use in MLE
nloglik <- function(dist, default_data = NULL) {
  ll <- loglik(dist, default_data)
  function(dist, data = default_data) { -sum(ll(dist, data)) }
}

insert <- function(vec, i, val) {
  if (i == 1)
    c(val, vec)
  else if (i == length(vec))
    c(vec, val)
  else
    c(vec[1:i-1], val, vec[i:length(vec)])
}

# Helper function: Fit a distribution where one parameter is constrained to be an integer
dist.fit.int <- function(dist, data, starting.value, i, max.iter = 100, ...) {
  old.nll <- nloglik(dist)
  iter <- 0
  new_start <- starting.value[1:length(starting.value) != i]
  try_estimate <- function(val) {
    nll <- function(params, data) {
      new_params <- insert(params, i, val)
      old.nll(new_params, data)
    }
    assign("iter", iter + 1, parent.frame())
    #if (iter > max.iter) {
      #stop("Dist.fit.int: maximum iterations reached")
    #}
    est <- nlm(nll, new_start, data=data, ...)
#    cat(paste("Trying val=", val, " -- Likelihood = ", est$minimum, " -- Params = ", est$estimate, "\n"))
    est$int_val <- val
    est
  }
  
  init_val <- starting.value[i]
  current <- try_estimate(init_val)
  left <- try_estimate(init_val - 1)
  right <- try_estimate(init_val + 1)
  
  repeat {
    if ((current$minimum <= left$minimum) & (current$minimum <= right$minimum))
      break;
    if (iter > max.iter)
      break;
    if ( (current$minimum - left$minimum) > (current$minimum - right$minimum) ) {
      right <- current
      current <- left
      left <- try_estimate(current$int_val - 1)
    } else {
      left  <- current
      current <- right
      right <- try_estimate(current$int_val + 1)
    }
  }

  est <- insert(current$estimate, i, current$int_val)
  names(est) <- names(starting.value)
  out <- list(estimate = est, likelihood = current$minimum, dist=dist, iter = iter)
  if (iter > max.iter) {
    warning("Maximum iterations reached.   Fit did not converge")
    out <- c(out, list(converge=F))
  } else
    out <- c(out, list(converge=T))
  class(out) <- c("distfit", "list")
  out 
}

# Generic distribution fit function
# Use Numeric approximation to compute the MLE estimate of the parameters
# number of parameters = length(starting.value)
dist.fit <- function(dist, data, starting.value, i = NULL, ...) {
  if (exists(paste("dist.fit.", dist, sep=""))) {
    f <- get(paste("dist.fit.", dist, sep=""))
    out <- f(dist, data, starting.value, ...)
    return(out)
  }
  if (!is.null(i)) {
    out <- dist.fit.int(dist, data, starting.value, i, ...)
    return(out)
  }
  nll <- nloglik(dist)
  est <- nlm(nll, starting.value, data=data, ...)
  out <- list(estimate = est$estimate, likelihood = est$minimum, dist=dist)
  out[['converge']] <- est$code < 4
  names(out$estimate) <- names(starting.value)
  class(out) <- c("distfit", "list")
  out
}

print.distfit <- function(x, ...) {
  if (is.null(names(x$estimate))) {
    params <- paste(x$estimate, collapse=",")
  } else {
    params <- paste(names(x$estimate), "=", x$estimate, sep="", collapse=",")
  }
  cat("Empirical Data Fit to a distribution:\n  ")
  cat(paste(x$dist, "(", params, ")", sep=""))
  cat(paste("\n\n  Log-Likelihood: ", x$likelihood, "\n", sep=""))
  if (!x$converge)
    cat(paste("\n Warning: Fit did not converge to a solution\n"))
}

demean <- function(x) {
  x - mean(x)
}

# Compute a log likelihood-ratio test between two non-nested distributions
# Null hypothesis is that both distributions are equally far from the true distribution
# Small p-values indicate that one distribution is a better fit than the other
# Sign of the D statistic indicates which distribution is better -- positive == #1

lr.test <- function(data, dist.one, params.one, dist.two, params.two) {
  ll.one <- loglik(dist.one)(params.one, data)
  ll.two <- loglik(dist.two)(params.two, data)
  R <- sum(ll.one - ll.two)
  sigsq <- sum( (demean(ll.one) - demean(ll.two)) ^ 2) / length(data)

  # erfc Copied from help(Normal)
  erfc <- function(x) 2 * pnorm(x * sqrt(2), lower = (x < 0))

  p <- erfc(R / sqrt(2 * length(data) * sigsq))
  names(R) = "D"
  nm.alt <- "The data fits the two distributions differently.\n   Positive D means the first distribution fits better"
  method <- "Non-nested Kolmogorov-Smirnov Test"
  data.name <- paste(dist.one, "vs.", dist.two)
  out <- list(statistic = R, p.value = p, alternative = nm.alt, method=method, data.name = data.name)
  class(out) <- c("htest", "list")
  out
}

start.value <- function(dist, data) {
  if (exists(paste("start.value.", dist, sep=""))) {
    f <- get(paste("start.value.", dist, sep=""))
    f(data)
  } else {
    stop(paste("Cannot find starting values for", dist))
  }
}

lr.test.fit <- function(data, fit.one, fit.two) {
  if (!(fit.one$converge)) {
    nm.alt <- "The data fits the two distributions differently.\n   Positive D means the first distribution fits better"
    data.name <- paste(fit.one$dist, "vs.", fit.two$dist)
    stat <- -1
    names(stat) <- "X"
    test <- list(statistic=stat, p.value=0, data.name = data.name, method="Non-convergence", alternative=nm.alt)
    class(test) <- c("htest", "list")
  } else if (!(fit.two$converge)) {
    nm.alt <- "The data fits the two distributions differently.\n   Positive D means the first distribution fits better"
    data.name <- paste(fit.one$dist, "vs.", fit.two$dist)
    stat <- 1
    names(stat) <- "X"
    test <- list(statistic=stat, p.value=0, data.name = data.name, method="Non-convergence", alternative=nm.alt)
    class(test) <- c("htest", "list")
  } else
    test <- lr.test(data, fit.one$dist, fit.one$estimate, fit.two$dist, fit.two$estimate)
  test
}

compare.dists.pair <- function(data, dists = c("binom", "pois")) {
  fits <- list()
  for (d in dists) {
#    cat(paste("Trying dist:", d, "\n"))
    sv <- start.value(d, data)
    fit <- dist.fit(d, data, sv)
    temp <- list()
    temp[[d]] <- fit
    fits <- c(fits, temp)
  }
  test <- lr.test.fit(data, fits[[1]], fits[[2]])
  fits[['test']] <- test
  fits[['dists']] <- dists
  class(fits) <- c("compdists.pair", "list")
  fits
}

print.compdists.pair <- function(x, ...) {
  print(x$test)
  if (x$test$p.value < 0.10) {   # Significantly different
    if (x$test$statistic > 0) 
      d <- x$dists[1]
    else
      d <- x$dists[2]
    print(x[[d]])
  }
}

compare.dists <- function(data, dists = c("binom", "pois", "disclnorm", "nbinom", "dpowerlaw", "geom", "discexp")) {
  # Calculate the MLE fit for each distribution
  fits <- list()
  for (d in dists) {
#    cat(paste("Trying dist:", d, "\n"))
    sv <- start.value(d, data)
    fit <- dist.fit(d, data, sv)
    temp <- list()
    temp[[d]] <- fit
    fits <- c(fits, temp)
  }
  
  res <- matrix(0, nrow=length(dists), ncol=length(dists), dimnames=list(dists, dists))
  # Calculate pairwise Likelihood ratio tests
  for (d1 in dists) 
    for (d2 in dists) {
      if (d1 >= d2) next
      test <- lr.test.fit(data, fits[[d1]], fits[[d2]])
      if (test$p.value < 0.10) {    # Statistically significant difference
        if (test$statistic > 0) {
          res[d1, d2] <- 1
          res[d2, d1] <- -1
        } else {
          res[d1, d2] <- -1
          res[d2, d1] <- 1
        }
      }
    }
  fits[['results']] <- res
  class(fits) <- c("compdists", "list")
  fits
}

print.compdists <- function(x, ...) {
  cat("Results of pairwise Likelihood Ratio Tests:\n")
  print(x$results)
  cat("\n")
  best <- apply(x$results, 1, sum)
  bestfits <- which(best == max(best))
  cat(paste("Best fitting distribution(s):", paste(names(best)[bestfits], collapse=","), "\n"))
  for (i in bestfits) {
    if (length(bestfits) > 1) {
      cat(paste(names(best)[i], ":\n", sep=""))
    }
    print(x[[names(best)[i]]])
  }
}

# --- Some distribution-specific functions

# - Binomial Distribution
dist.fit.binom <- function(dist, data, starting.value, ...) {
  dist.fit.int(dist, data, starting.value, 1, ...)
}

loglik.binom <- function(params, data = NULL) {
  n <- as.integer(params[1])
  p <- params[2]
  dbinom(data, n, p, log=T)
}

start.value.binom <- function(data) {
  out <- c(max(data)+1, 0.5)
  names(out) <- c("n", "p")
  out
}

# - Poisson Distribution
# Estimated using method of moments
start.value.pois <- function(data) {
  out <- mean(data)
  names(out) <- "lambda"
  out
}

# - Discretized Log-Normal distribution
ddisclnorm <- function(x, meanlog, sdlog, log=F) {
  p <- plnorm(x-0.5, meanlog=meanlog, sdlog=sdlog, lower.tail=F, log=F) - plnorm(x+0.5, meanlog=meanlog, sdlog=sdlog, lower.tail=F, log=F)
  if (log)
    log(p)
  else
    p
}

# Estimated using method of moments
start.value.disclnorm <- function(data) {
  meanlog <- mean(log(data))
  sdlog <- sd(log(data))
  out <- c(meanlog, sdlog)
  names(out) <- c("meanlog", "sdlog")
  out
}

# - Discrete Powerlaw (Zeta) distribution
start.value.dpowerlaw <- function(data) {
  out <- 2.5
  names(out) <- "alpha"
  out
}

# - Geometric distribution
start.value.geom <- function(data) {
  out <- 1/mean(data)
  names(out) <- "prob"
  out
}

# - Negative Binomial distribution
dist.fit.nbinom <- function(dist, data, starting.value, ...) {
  dist.fit.int(dist, data, starting.value, 1, ...)
}

# Estimated using method of moments
start.value.nbinom <- function(data) {
  p <- 1/mean(data)
  out <- c(1, p)
  names(out) <- c("size", "p")
  out
}

# - Discrete Exponential
ddiscexp <- function(x, lambda, log=F) {
  if (log)
    log(1-exp(-lambda)) - lambda * x
  else
    (1-exp(-lambda)) * exp(-lambda * x)
}

# Estimated using method of moments
start.value.discexp <- function(data) {
  out <- log(1 + length(data) / sum(data))
  names(out) <- "lambda"
  out
}

start.value.norm <- function(data) {
  out <- c(mean(data), sd(data))
  names(out) <= c("mean", "sd")
  out
}

start.value.lnorm <- function(data) {
  out <- c(mean(log(data)), sd(log(data)))
  names(out) <- c("meanlog", "sdlog")
  out
}

start.value.exp <- function(data) {
  out <- mean(data)
  names(out) <- "rate"
  out
}

start.value.powerlaw <- function(data) {
  out <- 2.5
  names(out) <- "alpha"
  out
}

start.value.unif <- function(data) {
  out <- c(min(data), max(data))
  names(out) <- c("min", "max")
  out
}

start.value.beta <- function(data) { 
  m <- mean(data)
  v <- var(data)
  a <- m * ( (m * (1 - m)) / v - 1)
  b <- (1 - m) * ( (m * (1-m)) / v - 1)
  out <- c(a,b)
  names(out) <- c("shape1", "shape2")
  out
}
