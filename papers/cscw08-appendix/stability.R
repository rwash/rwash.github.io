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
# stability.R
# Rick Wash <rwash@umich.edu>
#
# Utility functions to look at the development of tags on a given URL over time
# plot(tot(data, "cumulative")) recreates the Golder and Huberman plots
# plot(tot(data, "sliding")) uses a sliding window to illustrate how the distribution really isn't stable

# TOT -- Tags Over Time

# Usage:
# *** Grab site data from the database
# data <- site_data(db, delicious_id, table_prefix=jan2007)
#
# Now there are two things you can do with it:
# 1. Look at the Tag proportions Over Time (TOT)
# - info <- tot(data, type)
#   - type="cumulative": Cumulative percentages, ala Golder and Huberman
#   - type="sliding": Sliding window.   May specify window.size.  Defaults to 50
#   - type="moving": Moving average.  May specify alpha, the decay coefficient.
#   - type="raw": Raw, at the moment percentages.  Probably not very useful.
# - Now you can do normal things with this info variable:
#   - plot(info) is the most interesting.   Feel free to add any lattice-type options
#   - print(info), summary(info)
#
# 2. Look at the percentage of new tags as a function of time.
# - info <- pnew(data, type)
#   - type has the same four option as for tot
# - plot(info), print(info), summary(info) all work 
#
# There are two half-assed attempts at stability metrics here also:
# stability.rank: Calculates the manhattan distance between the tag ranks for each incremental unit of time.
# stability.wilcox: Does a wilcox sign-rank test for the percentages for each incremental unit of time.  Metric is the p-value
# stability.sq
# stability.swing:


# The basic idea -- there are some big swings, and we want to capture that.   So, for each tag over time, we calculate
# the change in probability over a given window (e.g. size 50).   Then the stability measure for that tag is the 
# MAX change in probability.   The site stability measure then is the average (or weighted average, with tag proportions as weights)
# of the individual tag probabilities.
#
# mean(stability.sq(info.lib.sli, transform=abs, aggregate=max, percent=T, window=50))


site_data <- function(db, delID, prefix="jan2007") {
  q <- paste("select s.position, s.user, t.tag from ", prefix, "_site s, ", prefix, "_tag t where s.id = t.site_id and deliciousID = '", delID, "'", sep="")
  out <- sqlQuery(db, q)
  out$tag <- factor(out$tag)
  out
}

# A class called "tot", or tags over time.
# plot.tot draws a pretty graph of the development of tags over time.
 
tot.cumulative <- function(data, ...) {
  zero <- rep(0, nlevels(data$tag)+2)
  names(zero) <- c("total", "position", levels(data$tag))
  cur.sum <- zero[3:length(zero)]
  total.tags <- 0
  out <- data.frame(P0 = zero)

  tags <- tapply(as.character(data$tag), data$position, c)
  for (pos in names(tags)) {
    for (t in tags[[pos]]) {
      cur.sum[t] <- cur.sum[t] + 1
      total.tags <- total.tags + 1
    }
    pct <- cur.sum / total.tags
    pct <- c(total.tags, as.integer(pos), pct)
    names(pct) <- c("total", "position", levels(data$tag))
    out[[paste("P", pos, sep="")]] <- pct
  }

  out <- as.data.frame(t(out))
  top.tags <- names(sort(tapply(data$tag, data$tag, length), dec=T))
  res <- list(type="Cumulative", data=out, top.tags=top.tags)
  class(res) <- c("tot.cumulative", "tot", "list")
  res
}

tot.moving <- function(data, alpha=0.05, ...) {
  zero <- rep(0, nlevels(data$tag)+2)
  names(zero) <- c("total", "position", levels(data$tag))
  cur.sum <- zero[3:length(zero)]
  total.tags <- 0
  out <- data.frame(P0 = zero)
  cum.pct <- cur.sum

  tags <- tapply(as.character(data$tag), data$position, c)
  for (pos in names(tags)) {
    cur.sum <- zero[3:length(zero)]
    total.tags <- 0
    for (t in tags[[pos]]) {
      cur.sum[t] <- cur.sum[t] + 1
      total.tags <- total.tags + 1
    }
    pct <- cur.sum / total.tags
    cum.pct <- alpha * pct + (1-alpha) * cum.pct
    out.pct <- c(total.tags, as.integer(pos), cum.pct)
    names(out.pct) <- c("total", "position", levels(data$tag))
    out[[paste("P", pos, sep="")]] <- out.pct
  }

  out <- as.data.frame(t(out))
  top.tags <- names(sort(tapply(data$tag, data$tag, length), dec=T))
  res <- list(type=paste("Moving Average, alpha=", alpha, sep=""), data=out, top.tags=top.tags)
  class(res) <- c("tot.moving", "tot", "list")
  res
}

tot.sliding <- function(data, window.size=50, ...) {
  zero <- rep(0, nlevels(data$tag)+2)
  names(zero) <- c("total", "position", levels(data$tag))
  cur.sum <- zero[3:length(zero)]
  moving.data <- data.frame(P0=c(0,cur.sum))
  total.tags <- 0
  out <- data.frame(P0 = zero)

  tags <- tapply(as.character(data$tag), data$position, c)
  for (pos in 1:max(data$position)) {
    temp_row <- zero[3:length(zero)]
    temp.total <- 0
    if (as.character(pos) %in% names(tags)) {
      for (t in tags[[as.character(pos)]]) {
        temp_row[t] <- temp_row[t] + 1
        temp.total <- temp.total + 1
      }
    }
    moving.data[[paste("P", pos, sep="")]] <- c(temp.total, temp_row)
    min_row <- max(0, as.integer(pos)-window.size)
    cols <- match(paste("P", c(min_row, pos), sep=""), names(moving.data))
    temp_data <- subset(moving.data, select=cols[1]:cols[2])
    sums <- apply(temp_data, 1, sum)
    moving.total <- sums[1]
    sums <- sums[2:length(sums)]
    pct <- if (moving.total > 0)
             sums / moving.total
           else sums
    pct <- c(moving.total, as.integer(pos), pct)
    names(pct) <- c("total", "position", levels(data$tag))
    out[[paste("P", pos, sep="")]] <- pct
  }

  out <- as.data.frame(t(out))
  top.tags <- names(sort(tapply(data$tag, data$tag, length), dec=T))
  res <- list(type=paste("Sliding Window, size=", window.size, sep=""), data=out, top.tags=top.tags)
  class(res) <- c("tot.sliding", "tot", "list")
  res
}

tot.raw <- function(data, ...) {
  zero <- rep(0, nlevels(data$tag)+2)
  names(zero) <- c("total", "position", levels(data$tag))
  cur.sum <- zero[3:length(zero)]
  total.tags <- 0
  out <- data.frame(P0 = zero)

  tags <- tapply(as.character(data$tag), data$position, c)
  for (pos in names(tags)) {
    cur.sum <- zero[3:length(zero)]
    total.tags <- 0
    for (t in tags[[pos]]) {
      cur.sum[t] <- cur.sum[t] + 1
      total.tags <- total.tags + 1
    }
    pct <- cur.sum / total.tags
    pct <- c(total.tags, as.integer(pos), pct)
    names(pct) <- c("total", "position", levels(data$tag))
    out[[paste("P", pos, sep="")]] <- pct
  }

  out <- as.data.frame(t(out))
  top.tags <- names(sort(tapply(data$tag, data$tag, length), dec=T))
  res <- list(type="Raw", data=out, top.tags=top.tags)
  class(res) <- c("tot.raw", "tot", "list")
  res
}

tot <- function(data, type = c("cumulative", "sliding", "raw", "moving"), ...) {
  type <- match.arg(type)
  name <- paste("tot.", type, sep="")
  f <- get(name)
  f(data, ...)
}

plot.tot <- function(x, min.prob=0.025, main=paste("Tags over Time,", x$type), xlab="Bookmark #", ylab="Percentage", ylim=c(0,0.5), type="l", ...) {
  require(reshape)
  require(lattice)
  temp.data <- melt(x$data, id.var=c("total", "position"), variable_name="tag")
  temp.data <- subset(temp.data, value > min.prob)
  xyplot(value ~ position, data=temp.data, groups=tag, main=main, xlab=xlab, ylab=ylab, ylim=ylim, type=type, ...)
}

print.tot <- function(x, ...) {
  print.data.frame(x$data)
}

summary.tot <- function(x, ...) {
  summary(x$data)
}

print.summary.tot <- function(x, ...) {

}

pnew.cumulative <- function(data, ...) {
  out <- pnew.sliding(data, window.size=max(data$position), ...)
  out$type <- "Probability of New Tag (Cumulative)"
  class(out) <- c("pnew.cumulative", "pnew", "list")
  out
}

pnew.sliding <- function(data, window.size =50, ...) {
  info <- pnew.raw(data, ...)
  out <- numeric(0)
  for (i in 1:length(info$data)) {
    start <- max(1, i - window.size)
    out <- c(out, mean(info$data[start:i]))
  }
  res <- list(type=paste("Probability of New Tag (Sliding Window, size=", window.size, ")", sep=""), data=out)
  class(res) <- c("pnew.sliding", "pnew", "list")
  res
}

pnew.moving <- function(data, alpha=0.1, ...) {
  info <- pnew.raw(data, ...)
  out <- info$data[1]
  for (i in 2:length(info$data)) 
    out <- c(out, alpha*info$data[i] + (1-alpha)*out[length(out)])
  res <- list(type=paste("Probability of New Tag (Moving Average, alpha=", alpha, ")", sep=""), data=out)
  class(res) <- c("pnew.moving", "pnew", "list")
  res
}

pnew.raw <- function(data, ...) {
  seen <- character(0)
  tags <- tapply(as.character(data$tag), data$position, c)
  out <- numeric(0)
  for (pos in 1:max(data$position)) {
    if (as.character(pos) %in% names(tags)) {
      seen.cur <- mean(tags[[as.character(pos)]] %in% seen)
      seen <- unique(c(seen, tags[[as.character(pos)]]))
      out <- c(out, 1-seen.cur)
    } else 
      out <- c(out, 0)
  }
  res <- list(type="Probability of New Tag", data=out)
  class(res) <- c("pnew.raw", "pnew", "list")
  res
}

pnew <- function(data, type=c("sliding", "moving", "raw"), ...) {
  type <- match.arg(type)
  name <- paste("pnew.", type, sep="")
  f <- get(name)
  f(data, ...)
}

print.pnew <- function(x, ...) {
  print(x$data)
}

plot.pnew <- function(x, main=x$type, ...) {
  require(lattice)
  data <- data.frame(Position=1:length(x$data), pnew=x$data)
  xyplot(pnew ~ Position, data=data, main=main, ...)
}

stability.rank <- function(tot) {
  ranks <- t(apply(tot$data, 1, rank))
  sapply(2:dim(ranks)[1], function(r) { dist(ranks[r-1:r,], method="manhattan")[1] })
}

stability.wilcox <- function(info, paired=F) {
  sapply(2:dim(info$data)[1], function(r) { wilcox.test(as.numeric(info$data[r-1,]), as.numeric(info$data[r,]), paired=paired)$p.value })
}

stability.sq <- function(info, top.tags = 25, transform = function(x) { x ^ 2 }, aggregate=sum, percent=T, start=100, window=1) {
  data <- info$data[(start-window):dim(info$data)[1],info$top.tags[1:top.tags]]
  temp <- c()
  for (i in (window+1):dim(data)[1]) {
    if (percent) {
      temp <- c(temp, ifelse(((data[i,] == 0) | (data[i-window,] == 0)), 0, (data[i,] - data[i-window,]) / data[i,]))
    } else {
      temp <- c(temp, ifelse(((data[i,] == 0) | (data[i-window,] == 0)), 0, (data[i,] - data[i-window,])))
    }
  }
  temp[is.nan(temp)] <- 0
  temp <- matrix(as.numeric(temp), ncol=dim(data)[2], byrow=T, dimnames=list(1:(dim(data)[[1]]-window), dimnames(data)[[2]]))
  temp <- transform(temp)
  out <- apply(temp, 2, aggregate)
  out
}

stability.swing <- function(info, top.tags=25, start=100, percent=F) {
  data <- info$data[start:dim(info$data)[1],info$top.tags[1:min(top.tags, dim(info$data)[2]-2)]]
  tag.stability <- apply(data, 2, max) - apply(data, 2, min)
  if (percent) {
    tag.stability <- tag.stability / apply(data, 2, min)
  }
  out <- mean(tag.stability)
  out
}

hypo_site <- function(db, id) {
  data <- site_data(db, id)
  size <- max(data$position)
  conf <- mcconfig.corrected()
  conf <- add_users(conf, c(NA, NA), "unbiased")
  data <- generate_site(size, conf)
  info.cum <- tot(data, "cum")
  info.sli <- tot(data, "sli")
  stab.cum <- stability.swing(info.cum)
  stab.sli <- stability.swing(info.sli)
  out <- c(stab.cum, stab.sli)
  names(out) <- c("Cum", "Sli")
  out
}

# Other possibilities:
# - manhattan distance on raw probs rather than ranks.
# - Do these probabilities fit in some sort of space?   What would be a distance metric in that space?
#   - On a sphere?  cosine...
# - Minimum value -- don't start computing stability until after a certain amount of bookmarks.
# - Look at why golder & huberman claim it is "stable" and try to measure that.


