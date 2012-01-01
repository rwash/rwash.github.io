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
# logistic.R
# Rick Wash <rwash@umich.edu>
#
# This file contains all of the code for running the generalized linear mixed model (glmm)
# regression on the del.icio.us data.  GLMM is a generalization of logistic regression.
# To run this the logistic regression on a data set, three steps are necessary:
# 1. Get the data into the database in the appropriate format
#    The database format is listed in the main appendix page.
#    You really need 2 datasets.
#    First, you need a set (<name>_site, <name>_tag) with all the bookmark information
#     for a set of URLs.
#    Second, you need a dataset (<name2>_user, <name2>_site, <name2>_tag) with all the bookmark
#     information of which sites all the users from the first set have bookmarked.  (user history)
#
# 2. Transform the data into the matrix format needed by the logistic regression
#    First, construct the user list:
#    - user_list <- logdata.fulllist(db, prefix.site=<name>, prefix.user=<name2>)
#    - dbWriteTable(db, "logdata_temp", user_list, append=T, row.names=F)
#    Next, process all of these users into the matrix format:
#    - logdata.runall(db, bysite=T)
#    (This last one takes a long time (almost a day for me), but is restartable if your computer
#     crashes)
#
#  3. Run the logistic regression on the converted data
#     To fit the model to a single URL, do:
#     - fit <- fit_site(<delicious_id>, db, type="bysite")
#     - summary(fit, db=db)
#     - You can also add a "limit=N" to limit the fit to the first N users.
#       - This is sometimes necessary for large fits (> 1000 users)
#     To fit the model to multiple delicious URLs, do this:
#     - fit_all <- fit_all_sites(db, type="bysite", ids=<id_list>)
#     - Summaries are automatically run on the fits
#     - You can also add a "limit=N" to limit the fit to the first N users
#     - printing fit_all prints a summary table
#     - lapply(fit_all, print) prints all the individual summaries

library(lme4)
library(RMySQL)

drv <- dbDriver("MySQL")
con <- dbConnect(drv, user="rwash", pass="*******", db="delicious")

  sqlQuery <- function(con, query) {
    rs <- dbSendQuery(con, query)
    data <- fetch(rs, n=-1)
    data
  }
  
ids <- unique(as.character(sqlQuery(con, "select deliciousID from ids")$deliciousID))
mc_ids <- 1:480



get_tag_history <- function(db, user, prefix="jun2007") {
  q <- paste("select s.deliciousID, s.position, t.tag from ", prefix, "_user u, ", prefix, "_site s, ", prefix, "_tag t where u.id = s.user_id and s.id = t.site_id  and u.user = '", user, "' order by s.date asc", sep="")
  data <- sqlQuery(db, q)
  data
}

users_tag_history <- function(...) { get_tag_history(...) }

user_tags_used <- function(history, delID) {
  if (dim(history)[1] == 0)
    return(character(0))
  s <- subset(history, deliciousID == delID, position)
  last_pos <- s$pos[1]
  info <- subset(history, position < last_pos)
  unique(as.character(info$tag))
}

user_tags_used.freq <- function(history, delID) {
  if (dim(history)[1] == 0)
    return(character(0))
  s <- subset(history, deliciousID == delID, position)
  last_pos <- s$pos[1]
  info <- subset(history, position < last_pos)
  out <- tapply(info$tag, factor(info$tag), length)
  out
}

site_info <- function(db, delID, prefix="jan2007") {
  q <- paste("select s.deliciousID, s.position, s.user, t.tag from ", prefix, "_site s, ", prefix, "_tag t where s.id = t.site_id and s.deliciousID = '", delID, "'", sep="")
  data <- sqlQuery(db, q)
  if (prefix == "mc") {
    real_id <- sqlQuery(db, paste("select distinct real_deliciousID from ", prefix, "_info where fake_deliciousID = '", delID, "'", sep=""))[[1]][1]
    attr(data, "real_id") <- real_id
  }
  data
}

site_userlist <- function(sinfo) {
  levels(sinfo$user)
}

site_tags <- function(sinfo) {
  levels(sinfo$tag)
}

site_tags.usedbefore.7 <- function(sinfo, cur_pos) {
  s <- subset(sinfo, position < cur_pos)
  tag_list <- factor(s$tag)
  tag_info <- tapply(tag_list, tag_list, length)
  tag_info
}

site_tags.usedbefore <- function(sinfo, cur_pos) {
  s <- subset(sinfo, position < cur_pos)
  tags <- unique(as.character(s$tag))
  tags
}

site_tags.countusedbefore <- function(si, cur_pos, tag_list) {
  s <- subset(si, position < cur_pos)
  counts <- tapply(s$tag, s$tag, length)
  out <- counts[tag_list]
  names(out) <- tag_list
  out[is.na(out)] <- 0
  out
}

site_usertags <- function(sinfo, u) {
  s <- subset(sinfo, user == u, tag)
  tags <- as.character(s$tag)
  tags
}

user_tags_count <- function(history, delID, tag_list) {
  if (dim(history)[1] == 0)
    return(character(0))
  s <- subset(history, deliciousID == delID, position)
  last_pos <- s$pos[1]
  info <- subset(history, position < last_pos)
  counts <- tapply(info$tag, info$tag, length)
  out <- counts[tag_list]
  names(out) <- tag_list
  out[is.na(out)] <- 0
  out
}

# Return a list of tags which are used more than once
multitags <- function(tags) {
  tag_freq <- tapply(tags, tags, length)
  top_tags <- names(tag_freq[tag_freq > 1])
  top_tags
}

# Structure of data for the logistic regression:
# Columns:
# - chosen        : 1 if this tag was chosen for this site, 0 otherwise
# - tag           : Name of tag this row refers to
# - user          : Name of user this row refers to
# - used.byuser   : 1 if this tag had been used before by this user
# - used.onsite   : 1 if this tag has been used previously to describe this site
# - tag_class     : <tag> if this tag is used more than once on the site.   "Other" otherwise
# 
# Regression equation (glm)
# logit(chosen) ~ used.byuser + used.onsite + used.byuser:used.onsite + tag_class + user

user_logdata <- function(user, site_info, user_tags, all_user_tags, type="all",  ...) {
  n <- paste("user_logdata.", type, sep="")
  if (exists(n))
    f <- get(n)
  else
    stop("Unknown type of dataset")
  f(user, site_info, user_tags, all_user_tags, ...)
}

# TODO: add a user_logdata.all_before where the tag list is the union of:
# - used.onsite (in the past)
# - used.byuser (in the past)
# - current choices
# Right now .all includes tags that were only used in the future on the site....
#  and past tags by the user..... 
user_logdata.tradeoff <- function(delID, u, sinfo = NULL, db.site, db.user = db.site, prefix.site = "jan2007", prefix.user = "jun2007") {
  if (is.null(sinfo)) {
    sinfo <- site_info(db.site, delID, prefix.site)
  }
  sinfo$tag <- gsub("\\\\", ":bs", sinfo$tag, perl=T, useBytes=T)
  user_info <- users_tag_history(db.user, u, prefix.user)
  user_info$tag <- gsub("\\\\", ":bs", user_info$tag, perl=T, useBytes=T)
  pos <- unique(subset(sinfo, user==u, position)$position)
  
  chosen_tags <- site_usertags(sinfo, u)
  site_tags <- unique(as.character(sinfo$tag))
  site_tags.usedbefore <- site_tags.usedbefore(sinfo, pos)
  user_tags <- unique(as.character(user_info$tag))
  user_tags.usedbefore <- user_tags_used(user_info, delID)
  
  all_tags <- unique(c(chosen_tags, site_tags, user_tags))
  N <- length(all_tags)
  
  out <- data.frame(id=rep(NA, N), site=rep(delID, N), user=rep(u, N), tag=all_tags, chosen = all_tags %in% chosen_tags, used.onsite = all_tags %in% site_tags.usedbefore, used.byuser = all_tags %in% user_tags.usedbefore, fromUserTags = all_tags %in% user_tags, fromSiteTags = all_tags %in% site_tags, position=rep(pos, N))
  out
}

user_logdata.tradeoff.bysite <- function(delID, u, sinfo = NULL, db.site, db.user = db.site, prefix.site = "jan2007", prefix.user = "jun2007") {
  if (is.null(sinfo)) {
    sinfo <- site_info(db.site, delID, prefix.site)
  }
  if (prefix.site == "mc") {
    # This is a simulated run.   Get the real deliciousID
    real_delID <- sqlQuery(db.site, paste("select real_deliciousID from mc_info where fake_deliciousID = \"", delID, "\"", sep=""))$real_deliciousID
  } else {
    real_delID <- delID
  }
  sinfo$tag <- gsub("\\\\", ":bs", sinfo$tag, perl=T, useBytes=T)
  user_info <- users_tag_history(db.user, u, prefix.user)
  user_info$tag <- gsub("\\\\", ":bs", user_info$tag, perl=T, useBytes=T)
  pos <- unique(subset(sinfo, user==u, position)$position)
  
  chosen_tags <- site_usertags(sinfo, u)
  site_tags <- unique(as.character(sinfo$tag))
  site_tags.usedbefore <- site_tags.usedbefore(sinfo, pos)
  user_tags <- unique(as.character(user_info$tag))
  user_tags.usedbefore <- user_tags_used(user_info, real_delID)
  
#  all_tags <- unique(c(chosen_tags, site_tags, user_tags))
  all_tags <- unique(c(chosen_tags, site_tags))
  N <- length(all_tags)
  
  out <- data.frame(id=rep(NA, N), site=rep(delID, N), user=rep(u, N), tag=all_tags, chosen = all_tags %in% chosen_tags, used.onsite = all_tags %in% site_tags.usedbefore, used.byuser = all_tags %in% user_tags.usedbefore, fromUserTags = all_tags %in% user_tags, fromSiteTags = all_tags %in% site_tags, position=rep(pos, N))
  out
}

user_logdata.tradeoff.7 <- function(delID, u, sinfo = NULL, db.site, db.user = db.site, prefix.site = "jan2007", prefix.user = "jun2007") {
  if (is.null(sinfo)) {
    sinfo <- site_info(db.site, delID, prefix.site)
  }
  if (prefix.site == "mc") {
    # This is a simulated run.   Get the real deliciousID
    real_delID <- sqlQuery(db.site, paste("select real_deliciousID from mc_info where fake_deliciousID = \"", delID, "\"", sep=""))$real_deliciousID
  } else {
    real_delID <- delID
  }
  sinfo$tag <- gsub("\\\\", ":bs", sinfo$tag, perl=T, useBytes=T)
  user_info <- users_tag_history(db.user, u, prefix.user)
  user_info$tag <- gsub("\\\\", ":bs", user_info$tag, perl=T, useBytes=T)
  pos <- unique(subset(sinfo, user==u, position)$position)
  
  chosen_tags <- site_usertags(sinfo, u)
  site_tags <- unique(as.character(sinfo$tag))
  site_tags.usedbefore <- site_tags.usedbefore.7(sinfo, pos)
  user_tags <- unique(as.character(user_info$tag))
  user_tags.usedbefore <- user_tags_used(user_info, real_delID)
  
#  all_tags <- unique(c(chosen_tags, site_tags, user_tags))
  all_tags <- unique(c(chosen_tags, site_tags))
  N <- length(all_tags)
  
  onsite <- c()
  for (tag in all_tags) {
    if (tag %in% names(site_tags.usedbefore)) {
      onsite <- c(onsite, site_tags.usedbefore[[tag]])
    } else {
      onsite <- c(onsite, 0)
    }
  }
  
  out <- data.frame(id=rep(NA, N), site=rep(delID, N), user=rep(u, N), tag=all_tags, chosen = all_tags %in% chosen_tags, used.onsite = onsite, used.byuser = all_tags %in% user_tags.usedbefore, fromUserTags = all_tags %in% user_tags, fromSiteTags = all_tags %in% site_tags, position=rep(pos, N))
  out
}

user_logdata.tradeoff.freq <- function(delID, u, sinfo = NULL, db.site, db.user = db.site, prefix.site = "jan2007", prefix.user = "jun2007") {
  if (is.null(sinfo)) {
    sinfo <- site_info(db.site, delID, prefix.site)
  }
  if (prefix.site == "mc") {
    # This is a simulated run.   Get the real deliciousID
    real_delID <- sqlQuery(db.site, paste("select real_deliciousID from mc_info where fake_deliciousID = \"", delID, "\"", sep=""))$real_deliciousID
  } else {
    real_delID <- delID
  }
  sinfo$tag <- gsub("\\\\", ":bs", sinfo$tag, perl=T, useBytes=T)
  user_info <- users_tag_history(db.user, u, prefix.user)
  user_info$tag <- gsub("\\\\", ":bs", user_info$tag, perl=T, useBytes=T)
  pos <- unique(subset(sinfo, user==u, position)$position)
  
  chosen_tags <- site_usertags(sinfo, u)
  site_tags <- unique(as.character(sinfo$tag))
  site_tags.usedbefore <- site_tags.usedbefore.7(sinfo, pos)
  user_tags <- unique(as.character(user_info$tag))
#  user_tags.usedbefore <- user_tags_used(user_info, real_delID)
  user_tags.usedbefore <- user_tags_used.freq(user_info, real_delID)
    
#  all_tags <- unique(c(chosen_tags, site_tags, user_tags))
  all_tags <- unique(c(chosen_tags, site_tags))
  N <- length(all_tags)
  
  onsite <- c()
  byuser <- c()
  for (tag in all_tags) {
    if (tag %in% names(site_tags.usedbefore)) {
      onsite <- c(onsite, site_tags.usedbefore[[tag]])
    } else {
      onsite <- c(onsite, 0)
    }
    if (tag %in% names(user_tags.usedbefore)) {
      byuser <- c(byuser, user_tags.usedbefore[[tag]])
    } else {
      byuser <- c(byuser, 0)
    }
  }
  
  
  out <- data.frame(id=rep(NA, N), site=rep(delID, N), user=rep(u, N), tag=all_tags, chosen = all_tags %in% chosen_tags, used.onsite = onsite, used.byuser = byuser, fromUserTags = all_tags %in% user_tags, fromSiteTags = all_tags %in% site_tags, position=rep(pos, N))
  out
}

user_logdata.save <- function(delID, u, sinfo = NULL, db.site, db.user=db.site, prefix.site="jan2007", prefix.user="jun2007") {
  data <- user_logdata.tradeoff(delID, u, sinfo, db.site, db.user, prefix.site, prefix.user)
  dbWriteTable(db.site, "logistic_data", data, append=T, row.names=F)
  dbSendQuery(db.site, paste("update logdata_temp set finished = TRUE where deliciousID = '", delID, "' and user = '", u, "'", sep=""))
  data
}

user_logdata.save.bysite <- function(delID, u, sinfo=  NULL, db.site, db.user=db.site, prefix.site="jan2007", prefix.user="jun2007") {
  data <- user_logdata.tradeoff.bysite(delID, u, sinfo, db.site, db.user, prefix.site, prefix.user)
  data <- subset(data, fromSiteTags | chosen)
  dbWriteTable(db.site, "logistic_data", data, append=T, row.names=F)
  dbSendQuery(db.site, paste("update logdata_temp set finished = TRUE where deliciousID = '", delID, "' and user = '", u, "'", sep=""))
  data
}

user_logdata.save.7 <- function(delID, u, sinfo=NULL, db.site, db.user=db.site, prefix.site="jan2007", prefix.user="jun2007") {
  data <- user_logdata.tradeoff.7(delID, u, sinfo, db.site, db.user, prefix.site, prefix.user)
  data <- subset(data, fromSiteTags | chosen)
  dbWriteTable(db.site, "logistic_data_seven", data, append=T, row.names=F)
  dbSendQuery(db.site, paste("update logdata_temp set finished = TRUE where deliciousID = '", delID, "' and user = '", u, "'", sep=""))
  data
}

user_logdata.save.freq <- function(delID, u, sinfo=NULL, db.site, db.user=db.site, prefix.site="jan2007", prefix.user="jun2007") {
  data <- user_logdata.tradeoff.freq(delID, u, sinfo, db.site, db.user, prefix.site, prefix.user)
  data <- subset(data, fromSiteTags | chosen)
  dbWriteTable(db.site, "logistic_data_freq", data, append=T, row.names=F)
  dbSendQuery(db.site, paste("update logdata_temp set finished = TRUE where deliciousID = '", delID, "' and user = '", u, "'", sep=""))
  data
}

make_user_list <- function(ids, db.site, prefix.site="jan2007", limit=NULL) {
  out <- data.frame(deliciousID=c(), user=c(), prefix=c())
  for (id in ids) {
    list <- logdata.userlist(id, db.site, prefix.site=prefix.site, limit=limit)
    out <- rbind(out, list)
  }
  out
}

logdata.userlist <- function(delID, db.site, db.user=db.site, prefix.site="jan2007", prefix.user="jun2007", limit=NULL) {
  sinfo <- site_info(db.site, delID, prefix.site)
  if (!is.null(limit)) {
    sinfo <- subset(sinfo, position <= limit)
  }
  user_list <- unique(as.character(sinfo$user))

  out <- data.frame(deliciousID = rep(delID, length(user_list)), user=user_list, prefix = rep(prefix.site, length(user_list)))
  out
}

logdata.fulllist <- function(db.site, db.user=db.site, prefix.site="jan2007", prefix.user="jun2007") {
  if (prefix.site == "jan2007") {
    ids <- sqlQuery(db.site, paste("select deliciousID from ids"))
  } else {
    ids <- sqlQuery(db.site, paste("select distinct deliciousID from ", prefix.site, "_site", sep=""))
  }
  ids <- unique(as.character(ids$deliciousID))
  
  out <- data.frame(delID=character(0), user=character(0))
  
  for (id in ids) {
    temp <- logdata.userlist(id, db.site, db.user, prefix.site, prefix.user)
    out <- rbind(out, temp)
  }
  
  out
}

logdata.runall <- function(dbcon, bysite=FALSE, seven=FALSE, freq=FALSE) {
  user_site_info <- sqlQuery(dbcon, "select deliciousID, user, prefix from logdata_temp where finished = FALSE")
  
  oldDelID <- NA
  sinfo <- NULL

  for (i in 1:length(user_site_info$deliciousID)) {
    delID <- user_site_info$deliciousID[i]
    user <- user_site_info$user[i]
    prefix <- user_site_info$prefix[i]
    if (is.null(sinfo) || (delID != oldDelID)) {
      cat("** Loading new site info\n")
      sinfo <- site_info(dbcon, delID, prefix )
    }
    cat(paste("Doing (", delID, ", ", user, ") ...", sep=""))
    if (bysite) {
      user_logdata.save.bysite(delID, user, sinfo, db.site=dbcon, prefix.site=prefix)
    } else { if (seven) {
      user_logdata.save.7(delID, user, sinfo, db.site=dbcon, prefix.site=prefix)
    } else { if (freq) {
      user_logdata.save.freq(delID, user, sinfo, db.site=dbcon, prefix.site=prefix)
    } else {
      user_logdata.save(delID, user, sinfo, db.site=dbcon, prefix.site=prefix)
    }}}
    cat(" Done.  ", length(user_site_info$deliciousID) - i, "left\n")
    oldDelID <- delID
  }
}

user_logdata.all <- function(user, site_info, user_tags, all_user_tags, ...) {
  user_used_onsite <- site_usertags(site_info, user)
  taglist <- unique(c(all_user_tags, levels(site_info$tag), user_used_onsite))
  top_tags <- multitags(site_info$tag)
  used.byuser <- taglist %in% user_tags
  u <- user
  pos <- unique(subset(site_info, user==u, position)$position)
  tags.used.onsite <- site_tags.usedbefore(site_info, pos)
  used.onsite <- taglist %in%tags.used.onsite
  tag_class <- ifelse(taglist %in% top_tags, taglist, "Other")
  chosen <- rep(0, length(taglist))
  names(chosen) <- taglist
  chosen[user_used_onsite] <- 1
  user <- rep(user, length(taglist))
  ids <- rep(site_info$deliciousID[1], length(taglist))
  out <- data.frame(chosen = chosen, tag=taglist, user=user, used.byuser = used.byuser, used.onsite=used.onsite, tag_class=tag_class, delID=ids, row.names=paste(user, taglist,sep=":"))
  out
}

user_logdata.sitetags <- function(user, site_info, user_tags, all_user_tags, ...) {
  taglist <- unique(as.character(site_info$tag))
  top_tags <- multitags(site_info$tag)
  user_used_onsite <- site_usertags(site_info, user)
  used.byuser <- taglist %in% user_tags
  u <- user
  pos <- unique(subset(site_info, user==u, position)$position)
  tags.used.onsite <- site_tags.usedbefore(site_info, pos)
  used.onsite <- taglist %in%tags.used.onsite
  tag_class <- ifelse(taglist %in% top_tags, taglist, "Other")
  chosen <- rep(0, length(taglist))
  names(chosen) <- taglist
  chosen[user_used_onsite] <- 1
  user <- rep(user, length(taglist))
  ids <- rep(site_info$deliciousID[1], length(taglist))
  out <- data.frame(chosen = chosen, tag=taglist, user=user, used.byuser = used.byuser, used.onsite=used.onsite, tag_class=tag_class, delID=ids, row.names=paste(user, taglist,sep=":"))
  out
}

user_logdata.sitecounts <- function(user, site_info, user_tags, all_user_tags, tag_hist, delID, ...) {
  taglist <- unique(as.character(site_info$tag))
  top_tags <- multitags(site_info$tag)
  user_used_onsite <- site_usertags(site_info, user)
  used.byuser <- user_tags_count(tag_hist, delID, taglist)
  u <- user
  pos <- unique(subset(site_info, user==u, position)$position)
  used.onsite <- site_tags.countusedbefore(site_info, pos, taglist)
  tag_class <- ifelse(taglist %in% top_tags, taglist, "Other")
  chosen <- rep(0, length(taglist))
  names(chosen) <- taglist
  chosen[user_used_onsite] <- 1
  user <- rep(user, length(taglist))
  ids <- rep(site_info$deliciousID[1], length(taglist))
  out <- data.frame(chosen = chosen, tag=taglist, user=user, used.byuser = used.byuser, used.onsite=used.onsite, tag_class=tag_class, delID=ids, row.names=paste(user, taglist,sep=":"))
  out
}

user_logdata.usertags <- function(user, site_info, user_tags, all_user_tags, ...) {
  user_used_onsite <- site_usertags(site_info, user)
  taglist <- unique(c(all_user_tags, user_used_onsite))
  top_tags <- multitags(site_info$tag)
  used.byuser <- taglist %in% user_tags
  u <- user
  pos <- unique(subset(site_info, user==u, position)$position)
  tags.used.onsite <- site_tags.usedbefore(site_info, pos)
  used.onsite <- taglist %in%tags.used.onsite
  tag_class <- ifelse(taglist %in% top_tags, taglist, "Other")
  chosen <- rep(0, length(taglist))
  names(chosen) <- taglist
  chosen[user_used_onsite] <- 1
  user <- rep(user, length(taglist))
  ids <- rep(site_info$deliciousID[1], length(taglist))
  out <- data.frame(chosen = chosen, tag=taglist, user=user, used.byuser = used.byuser, used.onsite=used.onsite, tag_class=tag_class, delID=ids, row.names=paste(user, taglist,sep=":"))
  out
}

logdata.bysite <- function(delID, db.siteinfo, min_tag_count = 5, limit=NULL) {
  q <- paste("select * from logistic_data where site = '", delID, "' and ( fromSiteTags = TRUE or chosen = TRUE)", sep="")
  if (!is.null(limit)) {
    q <- paste(q, " and position <= ", limit, sep="")
  }
  out <- sqlQuery(db.siteinfo, q)
  out$chosen <- factor(out$chosen, labels=c(FALSE, TRUE))
  out$used.onSite <- factor(out$used.onSite, labels=c(FALSE, TRUE))
  out$used.byUser <- factor(out$used.byUser, labels=c(FALSE, TRUE))
  out$fromSiteTags <- factor(out$fromSiteTags, labels=c(TRUE))
  out$fromUserTags <- factor(out$fromUserTags, labels=c(FALSE, TRUE))
  out$user <- factor(out$user)
  tag_list <- tapply(out$tag, list(tag=out$tag, chosen=out$chosen), length)
  popular_tags <- dimnames(tag_list)[['tag']][tag_list[,2] > min_tag_count]
  out$tag_class <- out$tag
  out$tag_class[!(out$tag %in% popular_tags)] <- "Other"
  out$tag_class <- factor(out$tag_class)
  out
}

logdata.seven <- function(delID, db.siteinfo, min_tag_count = 5, limit=NULL) {
  q <- paste("select * from logistic_data_seven where site = '", delID, "' and ( fromSiteTags = TRUE or chosen = TRUE)", sep="")
  if (!is.null(limit)) {
    q <- paste(q, " and position <= ", limit, sep="")
  }
  out <- sqlQuery(db.siteinfo, q)
  out$chosen <- factor(out$chosen, labels=c(FALSE, TRUE))
#  out$used.onSite <- as.numeric(out$used.onSite)
  out$used.byUser <- factor(out$used.byUser, labels=c(FALSE, TRUE))
  out$fromSiteTags <- factor(out$fromSiteTags, labels=c(TRUE))
  out$fromUserTags <- factor(out$fromUserTags, labels=c(FALSE, TRUE))
  out$user <- factor(out$user)
  tag_list <- tapply(out$tag, list(tag=out$tag, chosen=out$chosen), length)
  popular_tags <- dimnames(tag_list)[['tag']][tag_list[,2] > min_tag_count]
  out$tag_class <- out$tag
  out$tag_class[!(out$tag %in% popular_tags)] <- "Other"
  out$tag_class <- factor(out$tag_class)
  out
}

logdata.freq <- function(delID, db.siteinfo, min_tag_count = 5, limit=NULL) {
  q <- paste("select * from logistic_data_freq where site = '", delID, "' and ( fromSiteTags = TRUE or chosen = TRUE)", sep="")
  if (!is.null(limit)) {
    q <- paste(q, " and position <= ", limit, sep="")
  }
  out <- sqlQuery(db.siteinfo, q)
  out$chosen <- factor(out$chosen, labels=c(FALSE, TRUE))
#  out$used.onSite <- as.numeric(out$used.onSite)
#  out$used.byUser <- factor(out$used.byUser, labels=c(FALSE, TRUE))
  out$fromSiteTags <- factor(out$fromSiteTags, labels=c(TRUE))
  out$fromUserTags <- factor(out$fromUserTags, labels=c(FALSE, TRUE))
  out$user <- factor(out$user)
  tag_list <- tapply(out$tag, list(tag=out$tag, chosen=out$chosen), length)
  popular_tags <- dimnames(tag_list)[['tag']][tag_list[,2] > min_tag_count]
  out$tag_class <- out$tag
  out$tag_class[!(out$tag %in% popular_tags)] <- "Other"
  out$tag_class <- factor(out$tag_class)
  out
}
logdata.all <- function(delID, db, min_tag_count=5, limit=NULL) {
  q <- paste("select * from logistic_data where site = '", delID, "'", sep="")
  if (!is.null(limit)) {
    q <- paste(q, " and position <= ", limit, sep="")
  }
  out <- sqlQuery(db, q)
  out$chosen <- factor(out$chosen, labels=c(FALSE, TRUE))
  out$used.onSite <- factor(out$used.onSite, labels=c(FALSE, TRUE))
  out$used.byUser <- factor(out$used.byUser, labels=c(FALSE, TRUE))
  out$fromSiteTags <- factor(out$fromSiteTags, labels=c(FALSE, TRUE))
  out$fromUserTags <- factor(out$fromUserTags, labels=c(FALSE, TRUE))
  out$user <- factor(out$user)
  tag_list <- tapply(out$tag, list(tag=out$tag, chosen=out$chosen), length)
  popular_tags <- dimnames(tag_list)[['tag']][tag_list[,2] > min_tag_count]
  out$tag_class <- out$tag
  out$tag_class[!(out$tag %in% popular_tags)] <- "Other"
  out$tag_class <- factor(out$tag_class)
  out
}

fit_site <- function(delID, db, min_tag_count=5, type="all", limit=NULL, method="Laplace", include.data=F, tags=T) {
  ldfunc <- get(paste("logdata.", type, sep=""))
  ld <- ldfunc(delID, db, min_tag_count=min_tag_count, limit=limit)
  out <- del_info(delID, db)
  if (tags) {
    if (type == "freq") {
      m <- lmer(chosen ~ used.onSite + used.byUser + tag_class + (1|user), data=ld, 
      family=binomial(logit), method=method)
    } else {
      m <- lmer(chosen ~ used.onSite * used.byUser + tag_class + (1|user), data=ld, 
      family=binomial(logit), method=method)
    }
  } else {
    m <- lmer(chosen ~ used.onSite * used.byUser + (1|user), data=ld, 
    family=binomial(logit), method=method)
  }
  s <- summary(m)
  out <- c(out, list(fit=s, type=type))  # N=length(ld[[1]]), N=out$num_users, N=min(out$num_users, # limit)
  if (include.data) { out <- c(out, list(raw_data=ld)) }
  class(out) <- c("del.newfit", "list")
  out
}

fit_all_sites <- function(db, min_tag_count=5, type="all", limit=NULL, method="Laplace", ids=NULL, tags=T) {
  if (is.null(ids)) {
    ids <- unique(as.character(sqlQuery(db, "select deliciousID from ids")$deliciousID))
  }
  out <- lapply(ids, function(id) { 
    cat("Doing site: ", id, " ... \n");
    fit <- fit_site(id, db, min_tag_count=min_tag_count, type=type, limit=limit, method=method, include.data=T, tags=tags);
    fit.sum <- summary(fit, raw_data=fit$raw_data, db=db, min_tag_count=min_tag_count, limit=limit);
    fit <- NULL
    fit.sum
  })
  class(out) <- c("summary.multiple.del.newfit", "multiple.del.newfit", "list")
  out
}

fit_all_sites_mc <- function(db, min_tag_count=5, type="all", limit=NULL, method="Laplace", ids=NULL, tags=T) {
  if (is.null(ids)) {
    ids <- 1:480
  }
  out <- lapply(ids, function(id) { 
    cat("Doing site: ", id, " ... \n");
    fit <- fit_site(id, db, min_tag_count=min_tag_count, type=type, limit=limit, method=method, include.data=T, tags=tags);
    fit.sum <- summary(fit, raw_data=fit$raw_data, db=db, min_tag_count=min_tag_count, limit=limit);
    fit <- NULL
    site_info <- sqlQuery(db, paste("select * from mc_info where fake_deliciousID = \"", id, "\"", sep=""))
    fit.sum$user_type <- site_info$user_type
    fit.sum$Title <- site_info$real_deliciousID
    fit.sum$URL <- site_info$real_deliciousID
    fit.sum
  })
  class(out) <- c("summary.mc.multiple.del.newfit", "summary.multiple.del.newfit", "multiple.del.newfit", "list")
  out
}

reorder_by_type <- function(x) {
  user_type <- sapply(x, function(f) { f$user_type} )
  delID <- sapply(x, function(f) { f$Title} )
  id <- sapply(x, function(f) { f$deliciousID} )
  ordering <- order(user_type, delID, id)
  out <- x[ordering]
  class(out) <- class(x)
  out
}

reorder_by_id <- function(x) {
  user_type <- sapply(x, function(f) { f$user_type} )
  delID <- sapply(x, function(f) { f$Title} )
  id <- sapply(x, function(f) { f$deliciousID} )
  ordering <- order(delID, user_type, id)
  out <- x[ordering]
  class(out) <- class(x)
  out
}

predict.del.newfit <- function(x, data=NULL, family=binomial(logit)) {
  if (is.null(data)) {
    data <- model.frame(terms(x$fit), x$raw_data)
  }
  mat <- model.matrix(terms(x$fit), data)
  linkinv <- family$linkinv
  fit.value <- function(r) { linkinv(sum(fixef(x$fit) * r)) }
  fitted.values <- apply(mat, 1, fit.value)
  fitted.values
}

predict.lmer <- function(x, tag_class) {
  tc <- paste("tag_class", tag_class, sep="")
  base <- fixef(x)[1] 
  if (tc %in% names(fixef(x)))
    base <- base + fixef(x)[tc]
  onsite <- base + fixef(x)["used.onSiteTRUE"]
  byuser <- base + fixef(x)["used.byUserTRUE"]
  both <- base+fixef(x)["used.onSiteTRUE"] + fixef(x)["used.byUserTRUE"] + fixef(x)["used.onSiteTRUE:used.byUserTRUE"]
  out <- exp(c(base, onsite, byuser, both))
  out <- out / (1+out)
  names(out) <- c("Never Used", "Used Only On Site", "Used Only By User", "Recommended Tag")
  out
}

predict.lmer.freq <- function(x, tag_class) {
  tc <- paste("tag_class", tag_class, sep="")
  base <- fixef(x)[1] 
  if (tc %in% names(fixef(x)))
    base <- base + fixef(x)[tc]
#  row_nums = which(x$fit@X[,tc] == 1)
#  onsite_vals <- x$fit@X[row_nums,2]
#  byuser_vals <- x$fit@X[row_nums,3]
  onsite <- rep(fixef(x)["used.onSite"]*c(0,1,10,100,500), each=5)
  byuser <- rep(fixef(x)["used.byUser"]*c(0,1,10,100,500), 5)
  combined <- matrix(onsite + byuser + base, nrow=5)
  out <- exp(combined)
  out <- out / (1+out)
  attr(out, "tag") <- tag_class
  dimnames(out) <- list(c(0,1,10,100,500), c(0,1,10,100,500))
  out
}

print.del.newfit <- function(x, ...) {
  print(x$fit, ...)
}

summary.del.newfit <- function(x, raw_data=NULL, db=NULL, min_tag_count=4, limit=NULL, pTrue.fit=0.5) {
  if (is.null(raw_data)) {
    ldfunc <- get(paste("logdata.", x$type, sep=""))
    raw_data <- ldfunc(x$deliciousID, db, min_tag_count=min_tag_count, limit=limit)
  }
  x.sum <- summary(x$fit)
  coef.mat <- x$fit@coefs
  num.coef <- dim(coef.mat)[1]
  main.effects <- coef.mat[c(1,2,3,num.coef),]
  tag.effects <- coef.mat[4:(num.coef-1),]
  tag.effects <- tag.effects[sort.list(tag.effects[,1], dec=T),]
  main.effects.stars <- stars(main.effects[,4])
  tag.effects.stars <- stars(tag.effects[,4])
  ll <- logLik(x$fit)
  deviance <- deviance(x$fit)[1]   # same as -2LL
  num_users <- x$fit@ngrps
  REmat <- x$fit@REmat[1,3:4]
  AIC <- x$fit@AICtab[1,1]
  BIC <- x$fit@AICtab[1,2]
  
  
  fitted.values <- predict.del.newfit(x, data=raw_data)
  tag_names <- dimnames(tag.effects)[[1]]
  tag_names <- sub("tag_class", "", tag_names)
  if (x$type == "freq") {
    pred <- lapply(tag_names, function(y) { predict.lmer.freq(x$fit, y) })
  } else {
    pred <- sapply(tag_names, function(y) { predict.lmer(x$fit, y) })
    pred <- cbind(pred, Other=predict.lmer(x$fit, "Other"))
  }
    
  ICC <- x.sum@sigma / (x.sum@sigma + pi*pi/3)
  sigma <- x.sum@sigma
  
  N <- length(raw_data$chosen)
  df.residual <- length(raw_data$chosen) - nlevels(raw_data$tag_class) - 5

  # Goodness of fit tests
  dev.p <- pchisq(deviance, df.residual, lower.tail=F)
       # Note, x$fit$deviance is really -2LL
       # Statistics from: Applied Logistic Regression Analysis, Second Edition.   Scott Menard.  Sage University Press
  Dm <- deviance
  simple_fit <- glm(raw_data$chosen ~ 1, family=binomial(logit))
  Gm <- simple_fit$deviance - deviance
  Gm_df <- length(raw_data$chosen) - df.residual
  Gm_p <- pchisq(Gm, Gm_df, lower.tail=F)
  R2L <- Gm / (Gm + Dm)
  R2 <- summary(lm(fitted.values ~ raw_data$chosen))$r.squared
 
  # Fix what happens we we predict nothing chosen
  fitted.chosen <- factor(fitted.values >= pTrue.fit, levels=c(FALSE, TRUE))
  # Proportion of correct prediction tests
  error_table <- table(raw_data$chosen==TRUE, fitted.chosen) 
  num_errors <- sum(error_table) - sum(diag(error_table))
  lambda_ee <- min(tapply(raw_data$chosen, raw_data$chosen, length))
  lambda_p <- (lambda_ee - num_errors) / lambda_ee
  tau_ee <- 2 * prod(apply(error_table, 1, sum)) / N
  tau_p <- (tau_ee - num_errors) / tau_ee
  et <- error_table
  phi_ee <- ((et[1,1]+et[1,2])*(et[1,2]+et[2,2]) + (et[2,1]+et[2,2])*(et[1,1]+et[2,1])) / N
  phi_p <- (phi_ee - num_errors) / phi_ee
  lambda_exp_p <- lambda_ee / N
  tau_exp_p <- tau_ee / N
  phi_exp_p <- phi_ee / N
  real_p <- num_errors / N
  lambda_p_d <-(lambda_exp_p - real_p) / sqrt(lambda_exp_p * (1-lambda_exp_p) / N)
  tau_p_d <- (tau_exp_p - real_p) / sqrt(tau_exp_p * (1-tau_exp_p) / N)
  phi_p_d <- (phi_exp_p - real_p) / sqrt(phi_exp_p * (1-phi_exp_p) / N)
  
  lambda_p_d_p <- pchisq(lambda_p_d^2, 1, lower.tail=F)
  tau_p_d_p <- pchisq(tau_p_d^2, 1, lower.tail=F)
  phi_p_d_p <- pchisq(phi_p_d^2, 1, lower.tail=F)

  
  x$fit <- NULL
  x$raw_data <- NULL
  out <- c(x, list(main.effects=main.effects, main.effects.stars=main.effects.stars,
           tag.effects=tag.effects, tag.effects.stars=tag.effects.stars, loglik=ll,
           deviance=deviance, df.residual=df.residual, N=N, RE=REmat, AIC=AIC, BIC=BIC, sigma=sigma, predictions=pred,
           dev.p=dev.p, Gm=Gm, Gm.df=Gm_df, Gm.p=Gm_p, R2L=R2L, r.squared=R2, 
           num_users.estimated = num_users, error.table=error_table, ICC=ICC,
           lambda_p=lambda_p, lambda_p_d=lambda_p_d, lambda_p_d_p=lambda_p_d_p, 
           tau_p=tau_p, tau_p_d=tau_p_d, tau_p_d_p=tau_p_d_p,
           phi_p=phi_p, phi_p_d=phi_p_d, phi_p_d_p=phi_p_d_p, real_p=real_p
  ))
  class(out) <- c("summary.del.newfit", "del.newfit", "list")
  out
}

print.summary.del.newfit <- function(x, digits=4, ...) {
  # Information about what was being estimated
  cat(x$Title); cat("\n")
  cat(x$URL); cat("\n")
  cat(x$deliciousID); cat("\n")
  cat(paste("Total Number of Users of Site:", x$num_users, "\n"))
  cat(paste("Number of Users in Fit:", x$num_users.estimated, "\n"))
  cat(paste("Type of Data:", x$type, "\n"))

  # Parameter Estimates
  cat("\nMain Effects:\n")
  printCoefmat(x$main.effects)
  cat("\nTag Effects (in order of likelihood):\n")
  printCoefmat(x$tag.effects)
  cat("\nStandard Deviation on normal distribution of user values: ")
  cat(formatC(x$RE[1], digits=digits)); cat(" +- "); cat(formatC(x$RE[2], digits=digits))
  
  # Goodness of fit tests
  cat("\n\nGoodness of Fit Tests:\n")
  cat(paste("Residual Deviance:", formatC(x$deviance, digits=digits)))
  cat(paste(" on ", formatC(x$df.residual, digits=digits), " degrees of freedom", sep=""))
  cat(paste(" (p-value: ", formatC(x$dev.p, digits=digits), ")\n", sep=""))
  cat(paste("AIC:", formatC(x$AIC, digits=digits), "\n"))
  cat(paste("Gm: ", formatC(x$Gm, digits=digits), " on ", formatC(x$Gm.df, digits=digits), " degrees of freedom (p:value ", formatC(x$Gm.p, digits=digits), ")\n", sep=""))
  cat(paste("R^2_L: ", formatC(x$R2L, digits=digits), "\n", sep=""))
  cat(paste("R^2: ", formatC(x$r.squared, digits=digits), "\n", sep=""))

  cat("\nPredictive Power Tests\n")
  cat("Lambda_p: ", formatC(x$lambda_p, digits=digits), sep="")
    cat(" (d=", formatC(x$lambda_p_d, digits=digits), "; p-value:", formatC(x$lambda_p_d_p, digits=digits), ")")
    cat(" (for prediction models)\n")
  cat("Tau_p: ", formatC(x$tau_p, digits=digits), sep="")
    cat(" (d=", formatC(x$tau_p_d, digits=digits), "; p-value:", formatC(x$tau_p_d_p, digits=digits), ")")
    cat(" (for classification models)\n")
  cat("Phi_p: ", formatC(x$phi_p, digits=digits), sep="")
    cat(" (d=", formatC(x$phi_p_d, digits=digits), "; p-value:", formatC(x$phi_p_d_p, digits=digits), ")")
    cat(" (for selection models)\n")
  cat("Actual vs. Predicted Values:\n")
  print(x$error.table)

  # Predicted values
  cat("\nFitted Probabilities:\n")
  if (x$type == "freq") {
    cat("Horizontal: # of used.onSite\nVertial: # of used.byUser\n")
    lapply(x$predictions, function(y) { cat("----\nTag:", attr(y, "tag"), "\n"); print(y) })
  } else {
    print(x$predictions)
  }
}


summary.multiple.del.newfit <- function(x, db=NULL) {
#  out <- lapply(x, function(i) { summary.del.newfit(i, db=db)})
  out <- x
  class(out) <- c("summary.multiple.del.newfit", "multiple.del.newfit", "list")
  out
}

calc_real_p <- function(et) {
  sum(diag(et))/sum(et)
}

print.summary.multiple.del.newfit <- function(x) {
  rt <- results_table(x, URL=strtrim(URL, 30), N=num_users.estimated, onSite=main.effects[2,1], stars=main.effects.stars[2], byUser=main.effects[3,1], stars=main.effects.stars[3], Interact=main.effects[4,1], stars=main.effects.stars[4],
            Gm=Gm, stars.df=Gm.df, stars=stars(Gm.p), 
          "R^2_L"=R2L, #"R^2"=r.squared,
          real_p = calc_real_p(error.table), lambda_p=lambda_p, stars=stars(lambda_p_d_p))
  print(rt)
}

print.summary.mc.multiple.del.newfit <- function(x) {
  rt <- results_table(x, ID=deliciousID, Delicious=Title, Type=user_type, N=num_users.estimated, onSite=main.effects[2,1], stars=main.effects.stars[2], byUser=main.effects[3,1], stars=main.effects.stars[3], Interact=main.effects[4,1], stars=main.effects.stars[4],
            Gm=Gm, stars.df=Gm.df, stars=stars(Gm.p), 
          "R^2_L"=R2L, #"R^2"=r.squared,
          real_p = calc_real_p(error.table), lambda_p=lambda_p, stars=stars(lambda_p_d_p))
  print(rt)
}

latex.summary.multiple.del.newfit <- function(x) {
  rt <- results_table(x, Title=strtrim(Title, 60), N=num_users.estimated, onSite=main.effects[2,1], stars=main.effects.stars[2], byUser=main.effects[3,1], stars=main.effects.stars[3], Interact=main.effects[4,1], stars=main.effects.stars[4],
            Gm=Gm, stars.df=Gm.df, stars=stars(Gm.p), 
          "R^2_L"=R2L, #"R^2"=r.squared,
          real_p = calc_real_p(error.table), lambda_p=lambda_p, stars=stars(lambda_p_d_p))
  latex(rt)
}

get_data_from_fit <- function(fit.sum) {
  fe <- fixef(fit.sum)
  # Fixed effects of interest are the 2nd, 3rd, and last effects.   (1st is intercept)
  
}

logdata.bysite.generated <- function(gen_data, delID, db.userinfo, type="all", prefix.siteinfo = "jan2007", prefix.userinfo = "jun2007", limit=NULL, start=1) {
  if (is.null(db.userinfo))
    db.userinfo <- db.siteinfo
  si <- gen_data 
  if (!is.null(limit)) {
    si.sub <- subset(si, (position < start+limit) & (position >= start)); 
  } else {
    si.sub <- subset(si, position >= start)
  }
  si.sub$user <- factor(as.character(si.sub$user)); 
  si.sub$tag <- factor(as.character(si.sub$tag))
  user_list <- levels(si.sub$user)
  out <- data.frame()
  for (u in user_list) {
    cat(paste("Doing user:", u, "\n"))
    tag_hist <- get_tag_history(db.userinfo, u, prefix=prefix.userinfo)
    user_tags <- user_tags_used(tag_hist, delID)
    if (length(user_tags) > 0) {
      uld <- user_logdata(u, si, user_tags, all_user_tags=unique(as.character(tag_hist$tag)), tag_hist=tag_hist, type=type, delID=delID)
      out <- rbind(out, uld)
    }
  }
  out$tag <- factor(out$tag)
  # Fix tag_class
    tag_counts <- tapply(out$tag, list(tag=out$tag, chosen=out$chosen), length)
    out$tag_class <- as.character(out$tag)
    tags_left <- dimnames(tag_counts)[['tag']][(tag_counts[,2] > 5) & (!is.na(tag_counts[,2]))]
    out$tag_class[!(out$tag_class %in% tags_left)] <- "Other"
  out$tag_class <- factor(out$tag_class)
  out$user <- factor(out$user)
  out
}

logdata <- function(site_user_sample, db.siteinfo, db.userinfo=NULL, type="all", prefix.siteinfo = "jan2007", prefix.userinfo = "jun2007", limit=NULL, start=0) {
  if (is.null(db.userinfo))
    db.userinfo <- db.siteinfo
  if (!is.null(limit)) {
    si <- subset(si, (position <=start+limit) & (position > start)); 
    si$user <- factor(as.character(si$user)); 
    si$tag <- factor(as.character(si$tag))
  }
  out <- data.frame()
  row_nums <- 1:length(site_user_sample$user)
  for (r in row_nums) {
    delID <- as.character(site_user_sample$deliciousID)[r]
    u <- as.character(site_user_sample$user)[r]
    si <- site_info(db.siteinfo, delID, prefix=prefix.siteinfo)
    cat(paste("Doing user:", u, "from site:", delID, "\n"))
    tag_hist <- get_tag_history(db.userinfo, u, prefix=prefix.userinfo)
    user_tags <- user_tags_used(tag_hist, delID)
    uld <- user_logdata(u, si, user_tags, type)
    out <- rbind(out, uld)
  }
  out$tag <- factor(out$tag)
  out$tag_class <- factor(out$tag_class)
  out$user <- factor(out$user)
  out
  
}

sample_users_from_site <- function(delID, num, db, prefix="jan2007") {
  user_list <- sqlQuery(db, paste("select distinct user from ", prefix, "_site where deliciousID = '", delID, "'", sep=""))
  user_list <- as.character(user_list$user)
  if (num > length(user_list))
    return(user_list)
  sample(user_list, num, replace=F)
}

sample_sites <- function(ids, N.total, db, prefix="jan2007") {
  id.sample <- factor(sample(ids, N.total, replace=T))
  counts <- tapply(id.sample, id.sample, length)
  out <- data.frame()
  for (id in levels(id.sample)) {
    users <- sample_users_from_site(id, counts[id], db)
    info <- data.frame(deliciousID = rep(id, length(users)), user=users)
    out <- rbind(out, info)
  }
  out
}

predict.glmmML <- function(x, tag_class) {
  tc <- paste("tag_class", tag_class, sep="")
  base <- coef(x)[1] 
  if (tc %in% names(coef(x)))
    base <- base + coef(x)[tc]
  onsite <- base + coef(x)["used.onsiteTRUE"]
  byuser <- base + coef(x)["used.byuserTRUE"]
  both <- base+coef(x)["used.onsiteTRUE"] + coef(x)["used.byuserTRUE"] + coef(x)["used.onsiteTRUE:used.byuserTRUE"]
  out <- exp(c(base, onsite, byuser, both))
  out <- out / (1+out)
  names(out) <- c("Never Used", "Used Only On Site", "Used Only By User", "Recommended Tag")
  out
}

predict.del.fit <- function(x, data=NULL, family=binomial(logit)) {
  if (is.null(data)) {
    data <- model.frame(x$fit$terms, x$data)
  }
  mat <- model.matrix(x$fit$terms, data)
  linkinv <- family$linkinv
  fit.value <- function(r) { linkinv(sum(coef(x$fit) * r)) }
  fitted.values <- apply(mat, 1, fit.value)
  fitted.values
}

coef.tag <- function(x) { 
  it <- grep("^tag_class", names(coef(x)))
  out <- sort(coef(x)[it], dec=T)
  names(out) <- sub("tag_class", "", names(out))
  out
}

example.glmm <- function(x) {
  other <- predict.glmmML(x, "Other")
  tc <- coef.tag(x)
  top <- predict.glmmML(x, names(tc)[1])
  list(Other=other, "Top Tag"=top)
}

num_users <- function(delID, db, prefix="jan2007") {
  q <- paste("select count(distinct user) as num from ", prefix, "_site where deliciousID = '", delID, "'", sep="")
  info <- sqlQuery(db, q)
  info$num[1]
}

del_info <- function(delID, db, prefix="jan2007") {
  q <- paste("select distinct url, title from ", prefix, "_site where deliciousID = '", delID, "'", sep="")
  info <- sqlQuery(db, q)
  url <- info$url[1]
  title <- info$title[1]
  n <- num_users(delID, db, prefix)
  list(Title=title, URL=url, num_users=n, deliciousID=delID)
}


run_fit <- function(delID, db, start=1, limit=NULL, prefix.site="jan2007", prefix.user="jun2007", type="sitetags") {
  del.form <- chosen ~ used.onsite * used.byuser + tag_class
  require(glmmML)
  nfo <- del_info(delID, db, prefix.site)
  ld <- logdata.bysite(delID, db, start=start, limit=limit, prefix.site=prefix.site, prefix.user=prefix.user, type=type)
  fit <- glmmML(del.form, data=ld, family=binomial(logit), cluster=user)
  out <- c(nfo, list(fit=fit, data=ld, N=min(limit, nfo$num_users-start+1), type=type))
  class(out) <- c("del.fit", "list")
  out
}

run_fit.nouser_vars <- function(delID, db, start=1, limit=NULL, prefix.site="jan2007", prefix.user="jun2007", type="sitetags") {
  del.form <- chosen ~ used.onsite + tag_class
  require(glmmML)
  nfo <- del_info(delID, db, prefix.site)
  ld <- logdata.bysite(delID, db, start=start, limit=limit, prefix.site=prefix.site, prefix.user=prefix.user, type=type)
  fit <- glmmML(del.form, data=ld, family=binomial(logit), cluster=user)
  out <- c(nfo, list(fit=fit, data=ld, N=min(limit, nfo$num_users-start+1), type=type))
  class(out) <- c("del.fit", "list")
  out
}

run_fit.nouser_effects <- function(delID, db, start=1, limit=NULL, prefix.site="jan2007", prefix.user="jun2007", type="sitetags") {
  del.form <- chosen ~ used.onsite * used.byuser + tag_class
  require(glmmML)
  nfo <- del_info(delID, db, prefix.site)
  ld <- logdata.bysite(delID, db, start=start, limit=limit, prefix.site=prefix.site, prefix.user=prefix.user, type=type)
  fit <- glm(del.form, data=ld, family=binomial(logit))
  out <- c(nfo, list(fit=fit, data=ld, N=min(limit, nfo$num_users-start+1), type=type))
  class(out) <- c("del.fit", "list")
  out
}

stars <- function(p.vals) {
    format(ifelse(p.vals < 0.001, "***", ifelse(p.vals < 0.01, "**", ifelse(p.vals < 0.05, "*", ifelse(p.vals < 0.1, ".", " ")))), width=3)
}

summary.del.fit <- function(x, pTrue.fit = 0.5, ...) {
  
  # Calculate Wald test values for individual parameter estimates
  ind.tag <- grep("^tag_class", names(coef(x$fit)))
  ind.main <- which(!(1:length(coef(x$fit)) %in% ind.tag))
  coef <- coef(x$fit)[ind.main]
  se <- x$fit$coef.sd[ind.main]
  t.vals <- coef / se
  p.vals <- pchisq(t.vals^2, 1, lower.tail=F)
  cm.main <- cbind(coef, se, t.vals, p.vals)
  dimnames(cm.main) <- list(names(coef),  c("Estimate", "Std. Error", "t value", "Pr(>|t|)"))
  ind.tag <- ind.tag[sort.list(coef(x$fit)[ind.tag], dec=T)]
  coef <- coef(x$fit)[ind.tag]
  se <- x$fit$coef.sd[ind.tag]
  t.vals <- coef / se
  p.vals <- pchisq(t.vals ^ 2, 1, lower.tail=F)
  cm.tag <- cbind(coef, se, t.vals, p.vals)
  dimnames(cm.tag) <- list(names(coef),  c("Estimate", "Std. Error", "t value", "Pr(>|t|)"))
  p <- example.glmm(x$fit)
  ordered_tags <- coef.tag(x$fit)
  pred <- sapply(names(ordered_tags), function(y) { predict.glmmML(x$fit, y) })
  pred <- cbind(pred, Other=predict.glmmML(x$fit, "Other"))

  N <- length(x$data$chosen)
  fitted.values <- predict.del.fit(x)

  ICC <- x$fit$sigma / (x$fit$sigma + pi*pi/3)

  # Goodness of fit tests
  dev.p <- pchisq(x$fit$deviance, x$fit$df.residual, lower.tail=F)
       # Note, x$fit$deviance is really -2LL
       # Statistics from: Applied Logistic Regression Analysis, Second Edition.   Scott Menard.  Sage University Press
  Dm <- x$fit$deviance
  simple_fit <- glm(x$data$chosen ~ 1, family=binomial(logit))
  Gm <- simple_fit$deviance - x$fit$deviance
  Gm_df <- length(x$data$chosen) - x$fit$df
  Gm_p <- pchisq(Gm, Gm_df, lower.tail=F)
  R2L <- Gm / (Gm + Dm)
  R2 <- summary(lm(fitted.values ~ x$data$chosen))$r.squared
 
  # Proportion of correct prediction tests
  error_table <- table(as.logical(x$data$chosen), fitted.values >= pTrue.fit) 
  num_errors <- sum(error_table) - sum(diag(error_table))
  lambda_ee <- min(tapply(x$data$chosen, x$data$chosen, length))
  lambda_p <- (lambda_ee - num_errors) / lambda_ee
  tau_ee <- 2 * prod(apply(error_table, 1, sum)) / N
  tau_p <- (tau_ee - num_errors) / tau_ee
  et <- error_table
  phi_ee <- ((et[1,1]+et[1,2])*(et[1,2]+et[2,2]) + (et[2,1]+et[2,2])*(et[1,1]+et[2,1])) / N
  phi_p <- (phi_ee - num_errors) / phi_ee
  lambda_exp_p <- lambda_ee / N
  tau_exp_p <- tau_ee / N
  phi_exp_p <- phi_ee / N
  real_p <- num_errors / N
  lambda_p_d <-(lambda_exp_p - real_p) / sqrt(lambda_exp_p * (1-lambda_exp_p) / N)
  tau_p_d <- (tau_exp_p - real_p) / sqrt(tau_exp_p * (1-tau_exp_p) / N)
  phi_p_d <- (phi_exp_p - real_p) / sqrt(phi_exp_p * (1-phi_exp_p) / N)
  
  lambda_p_d_p <- pchisq(lambda_p_d^2, 1, lower.tail=F)
  tau_p_d_p <- pchisq(tau_p_d^2, 1, lower.tail=F)
  phi_p_d_p <- pchisq(phi_p_d^2, 1, lower.tail=F)
  
  out <- c(x, list(cm.main = cm.main, cm.tag = cm.tag, predictions=pred, tags=ordered_tags, 
           dev.p=dev.p, Gm=Gm, Gm.df=Gm_df, Gm.p=Gm_p, R2L=R2L, r.squared=R2, 
           fitted.values=fitted.values, error.table=error_table, ICC=ICC,
           lambda_p=lambda_p, lambda_p_d=lambda_p_d, lambda_p_d_p=lambda_p_d_p, 
           tau_p=tau_p, tau_p_d=tau_p_d, tau_p_d_p=tau_p_d_p,
           phi_p=phi_p, phi_p_d=phi_p_d, phi_p_d_p=phi_p_d_p
           ))
  class(out) <- c("summary.del.fit", class(x))
  out
}

print.summary.del.fit <- function(x, digits=4, ...) {
  # Information about what was being estimated
  cat(x$Title); cat("\n")
  cat(x$URL); cat("\n")
  cat(x$deliciousID); cat("\n")
  cat(paste("Total Number of Users of Site:", x$num_users, "\n"))
  cat(paste("Number of Users in Fit:", x$N, "\n"))
  cat(paste("Type of Data:", x$type, "\n"))

  # Parameter Estimates
  cat("\nMain Effects:\n")
  printCoefmat(x$cm.main)
  cat("\nTag Effects (in order of likelihood):\n")
  printCoefmat(x$cm.tag)
  cat("\nStandard Deviation on normal distribution of user values: ")
  cat(formatC(x$fit$sigma, digits=digits)); cat(" +- "); cat(formatC(x$fit$sigma.sd, digits=digits))
  
  # Goodness of fit tests
  cat("\n\nGoodness of Fit Tests:\n")
  cat(paste("Residual Deviance:", formatC(x$fit$deviance, digits=digits)))
  cat(paste(" on ", formatC(x$fit$df.residual, digits=digits), " degrees of freedom", sep=""))
  cat(paste(" (p-value: ", formatC(x$dev.p, digits=digits), ")\n", sep=""))
  cat(paste("AIC:", formatC(x$fit$aic, digits=digits), "\n"))
  cat(paste("Gm: ", formatC(x$Gm, digits=digits), " on ", formatC(x$Gm.df, digits=digits), " degrees of freedom (p:value ", formatC(x$Gm.p, digits=digits), ")\n", sep=""))
  cat(paste("R^2_L: ", formatC(x$R2L, digits=digits), "\n", sep=""))
  cat(paste("R^2: ", formatC(x$r.squared, digits=digits), "\n", sep=""))

  cat("\nPredictive Power Tests\n")
  cat("Lambda_p: ", formatC(x$lambda_p, digits=digits), sep="")
    cat(" (d=", formatC(x$lambda_p_d, digits=digits), "; p-value:", formatC(x$lambda_p_d_p, digits=digits), ")")
    cat(" (for prediction models)\n")
  cat("Tau_p: ", formatC(x$tau_p, digits=digits), sep="")
    cat(" (d=", formatC(x$tau_p_d, digits=digits), "; p-value:", formatC(x$tau_p_d_p, digits=digits), ")")
    cat(" (for classification models)\n")
  cat("Phi_p: ", formatC(x$phi_p, digits=digits), sep="")
    cat(" (d=", formatC(x$phi_p_d, digits=digits), "; p-value:", formatC(x$phi_p_d_p, digits=digits), ")")
    cat(" (for selection models)\n")
  cat("Actual vs. Predicted Values:\n")
  print(x$error.table)

  # Predicted values
  cat("\nFitted Probabilities:\n")
  print(x$predictions)
}

print.del.fit <- function(x, ...) {
  cat(x$Title); cat("\n")
  cat(x$URL); cat("\n")
  cat(paste("Number of Users:", x$num_users, "\n"))
  print(x$fit)
}

run_all_sites <- function(ids, con, N) {
  out <- lapply(ids, function(x) {run_site(x, con, limit=N)})
  names(out) <- ids;
  class(out) <- c("multiple.del.fit", "list")
  out
}

percent_correct <- function(tab) {
  sum(diag(tab)) / sum(tab) * 100
}

summary.multiple.del.fit <- function(x, recalc=T, url=F) {
  if (recalc) {
    x <- lapply(x, summary.del.fit)
  } else {
    x <- x$sums
  }

  effects.cum <- c()
  p.vals.cum <- c()
  dev.cum <- c()
  stars.cum <- c()
  gm.cum <- c()
  gm.df.cum <- c()
  gm.stars.cum <- c()
  r2l.cum <- c()

  ids <- names(x)
  if (is.null(ids)) {
    ids <- 1:length(x)
  }
  for (id in ids) {
    fit <- x[[id]]
    effects <- fit$cm.main[,1]
    p.vals <- fit$cm.main[,4]
    dev <- c(fit$fit$deviance, fit$fit$df.residual)
    stars <- ifelse(p.vals < 0.001, "***", ifelse(p.vals < 0.01, "**", ifelse(p.vals < 0.05, "*", ifelse(p.vals < 0.1, ".", " "))))
    gm <- fit$Gm
    gm.df <- fit$Gm.df
    gm.p <- fit$Gm.p
    gm.stars <- ifelse(gm.p < 0.001, "***", ifelse(gm.p < 0.01, "**", ifelse(gm.p < 0.05, "*", ifelse(gm.p < 0.1, ".", " "))))
    r2l <- fit$R2L

    effects.cum <- c(effects.cum, effects)
    p.vals.cum <- c(p.vals.cum, p.vals)
    dev.cum <- c(dev.cum, dev)
    stars.cum <- c(stars.cum, stars)
    gm.cum <- c(gm.cum, gm)
    gm.df.cum <- c(gm.df.cum, gm.df)
    gm.stars.cum <- c(gm.stars.cum, gm.stars)
    r2l.cum <- c(r2l.cum, r2l)
  }
  if (url) {
    ids <- sapply(x, function(y) { y$URL })
  } else {
    ids <- sapply(x, function(y) { y$deliciousID })
  }
  main.names <- c("Intercept", "Used.onSite", "Used.byUser", "Interaction")[1:length(fit$cm.main[,1])]
  effects <- matrix(effects.cum, ncol=length(main.names), byrow=T, dimnames=list(ids, main.names))
  p.vals <- matrix(p.vals.cum, ncol=length(main.names), byrow=T, dimnames=list(ids, main.names))
  dev <- matrix(dev.cum, ncol=2, byrow=T, dimnames=list(ids, c("Deviance", "DF")))
  stars <- matrix(stars.cum, ncol=length(main.names), byrow=T, dimnames=list(ids, main.names))
  out <- list(effects=effects, p.vals = p.vals, stars=stars, sums=x, Gm=gm.cum, Gm.df = gm.df.cum, Gm.stars=gm.stars.cum, R2L=r2l.cum)
  class(out) <- c("summary.multiple.del.fit", "matrix")
  out
}

print.summary.multiple.del.fit.old <- function(x, show.model.fit=T, digits=4, separate=F) {
  cat(format("Delicious ID", width=32, justify="centre"))
  cat(" ")
  for (n in dimnames(x$effect)[[2]]) {
    cat(format(n, width=12, justify="right"))
    cat("   ")
  }
  if (show.model.fit) {
    cat(" ")
    cat(format("Gm ", width=14, justify="centre"))
    cat(" ")
    cat(format("R^2_L", width=6, justify="right"))
  }
  cat("\n")
  for (r in 1:dim(x$effect)[1]) {
    cat(format(strtrim(dimnames(x$effect)[[1]][r], width=32), width=32), " ", sep="")
    for (i in 1:dim(x$effect)[2]) {
      cat(format(x$effect[r,i], trim=T, digits=digits, width=8), " ", format(x$stars[r,i], width=3), "   ", sep="")
    }
    if (show.model.fit) {
      cat(" ")
      cat(format(x$Gm[r], digits=4, width=5), "(", format(x$Gm.df[r], digits=2, width=2),")", " ", format(x$Gm.stars[r], width=3), sep="")
      cat("  ")
      cat(format(x$R2L[r], digits=5))
    }
    cat("\n")
  }
  cat("---\nSignif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 0.99 '#' 1\n") 
  if (separate) {
    lapply(x$sums, print)
    return(NULL)
  }
}

print.summary.multiple.del.fit <- function(x, ...) {
  tab <- results_table(x,
          URL=strtrim(URL, 50), 
          Users=N, 
          Used.onSite=cm.main[2,1], stars.Used.onSite=stars(cm.main[2,4]), 
          Used.byUser=cm.main[3,1], stars=stars(cm.main[3,4]), 
          Interact=cm.main[4,1], stars=stars(cm.main[4,4]), 
          Gm=Gm, stars.df=Gm.df, stars=stars(Gm.p), 
          "R^2_L"=R2L, 
          Sigma=fit$sigma)
  print(tab)
}

diagnostics <- function(x, ...) {
  UseMethod("diagnostics")
}

summary.summary.multiple.del.fit <- function(x, ...) {
  summary.multiple.del.fit(x, recalc=F, ...)
}

diagnostics.summary.multiple.del.fit <- function(x) {
  # Titles
  cat(format("Delicious ID", width=32, justify="centre"))
  cat(" ")
  cat(format("Gm ", width=14, justify="centre"))
  cat("  ")
  cat(format("R^2_L", width=6, justify="right"))
  cat(" ")
  cat(format("R^2", width=6, justify="centre"))
  cat(" ")
  cat(format("% Correct", width=10, justify="right"))
  cat(" ")
  cat(format("Lambda_p", width=11, justify="centre"))
  cat(" ")
  cat(format("Tau_p", width=11, justify="centre"))
  cat(" ")
  cat(format("Phi_p", width=11, justify="centre"))
  cat("\n")

  for (r in 1:dim(x$effect)[1]) {
    cat(format(strtrim(dimnames(x$effect)[[1]][r], width=32), width=32), " ", sep="")
    cat(" ")
    cat(format(x$Gm[r], digits=4, width=5), "(", format(x$Gm.df[r], digits=2, width=2),")", " ", format(x$Gm.stars[r], width=3), sep="")
    cat("  ")
    cat(format(x$R2L[r], digits=4, width=6))
    cat(" ")
    cat(format(x$sums[[r]]$r.squared, digits=4, width=6))
    cat(" ")
    cat(format((sum(diag(x$sums[[r]]$error.table)) / sum(x$sums[[r]]$error.table)) * 100, digits=4, width=10, nsmall=2))
    cat(" ")
    cat(format(x$sums[[r]]$lambda_p, digits=4, width=7), stars(x$sums[[r]]$lambda_p_d_p))
    cat(" ")
    cat(format(x$sums[[r]]$tau_p, digits=4, width=7), stars(x$sums[[r]]$tau_p_d_p))
    cat(" ")
    cat(format(x$sums[[r]]$phi_p, digits=4, width=7), stars(x$sums[[r]]$phi_p_d_p))
    cat("\n")
  }
  cat("---\nSignif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 0.99 '#' 1\n") 
}
  
html <- function(x, ...) {
  UseMethod("html")
}

html.summary.multiple.del.fit <- function(x, digits=4) {
  cat("<table class=\"delicious_fit\">\n<tr>")
  cat("<th>",format("Delicious ID", width=32, justify="centre"), "</th>")
  for (n in dimnames(x$effect)[[2]]) {
    cat("<th colspan=2>", format(n, width=12, justify="right"), "</th>")
    cat("   ")
  }
  cat("</tr>\n<tr>")
  for (r in 1:dim(x$effect)[1]) {
    cat("<td>", dimnames(x$effect)[[1]][r], "</td>")
    for (i in 1:dim(x$effect)[2]) {
      cat("<td class=\"fit_estimate\">",format(x$effect[r,i], trim=T, digits=digits, width=8), "</td><td class=\"fit_stars\">", format(x$stars[r,i], width=3), "</td>")
    }
    cat("</tr>\n<tr>")
  }
  cat("<td colspan=0>Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 0.99 '#' 1</td></tr>\n</table>") 
}

html.diagnostics <- function(x) {
  # Titles
  cat("<table class=\"delicious_fit\">\n<tr><th>")
  cat(format("Delicious ID", width=32, justify="centre"))
  cat("</th><th colspan=2>")
  cat(format("Gm ", width=14, justify="centre"))
  cat("</th><th>")
  cat(format("R^2_L", width=6, justify="right"))
  cat("</th><th>")
  cat(format("R^2", width=6, justify="centre"))
  cat("</th><th>")
  cat(format("% Correct", width=10, justify="right"))
  cat("</th><th colspan=2>")
  cat(format("Lambda_p", width=11, justify="centre"))
  cat("</th><th colspan=2>")
  cat(format("Tau_p", width=11, justify="centre"))
  cat("</th><th colspan=2>")
  cat(format("Phi_p", width=11, justify="centre"))
  cat("</th></tr>\n<tr>")

  for (r in 1:dim(x$effect)[1]) {
    cat("<td>")
    cat(format(strtrim(dimnames(x$effect)[[1]][r], width=32), width=32), " ", sep="")
    cat("</td><td class=\"fit_estimate\">")
    cat(format(x$Gm[r], digits=4, width=5), "(", format(x$Gm.df[r], digits=2, width=2),")", "</td><td class=\"fit_stars\">", format(x$Gm.stars[r], width=3), sep="")
    cat("</td><td>")
    cat(format(x$R2L[r], digits=4, width=6))
    cat("</td><td>")
    cat(format(x$sums[[r]]$r.squared, digits=4, width=6))
    cat("</td><td class=\"fit_estimate\">")
    cat(format((sum(diag(x$sums[[r]]$error.table)) / sum(x$sums[[r]]$error.table)) * 100, digits=4, width=10, nsmall=2))
    cat("</td><td class=\"fit_estimate\">")
    cat(format(x$sums[[r]]$lambda_p, digits=4, width=7), "</td><td class=\"fit_stars\">", stars(x$sums[[r]]$lambda_p_d_p))
    cat("</td><td class=\"fit_estimate\">")
    cat(format(x$sums[[r]]$tau_p, digits=4, width=7), "</td><td class=\"fit_stars\">", stars(x$sums[[r]]$tau_p_d_p))
    cat("</td><td class=\"fit_estimate\">")
    cat(format(x$sums[[r]]$phi_p, digits=4, width=7), "</td><td class=\"fit_stars\">", stars(x$sums[[r]]$phi_p_d_p))
    cat("</tr>\n<tr>")
  }
  cat("<td colspan=0>Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 0.99 '#' 1</td></tr>\n</table>") 
}

latex <- function(x, ...) {
  UseMethod("latex")
}

results_table <- function(x, ...) {
  UseMethod("results_table")
}

results_table.default <- function(data, ...) {
  dots <- match.call(expand.dots=F)$...
  out <- data.frame(lapply(dots, function(n) { 
    if (mode(n) == "call")
      eval(n, data)
    else data[[as.character(n)]]
  }))
  class(out) <- c("results_table", class(out))
  out
}

results_table.multiple.del.newfit <- function(data, ...) {
  dots <- match.call(expand.dots=F)$...
  do_element <- function(c, sum) {
    if (mode(c) == "call") {
      eval(c, sum)
    } else {
      sum[[as.character(c)]]
    }
  }
  do_column <- function(c) {
    sapply(1:length(data), function(i) { do_element(c, data[[i]]) })
  }
  out <- data.frame(lapply(dots, do_column))
  class(out) <- c("results_table", class(out))
  out
}

results_table.summary.multiple.del.fit <- function(data, ...) {
  dots <- match.call(expand.dots=F)$...
  do_element <- function(c, sum) {
    if (mode(c) == "call") {
      eval(c, sum)
    } else {
      sum[[as.character(c)]]
    }
  }
  do_column <- function(c) {
    sapply(1:length(data$sums), function(i) { do_element(c, data$sums[[i]]) })
  }
  out <- data.frame(lapply(dots, do_column))
  class(out) <- c("results_table", class(out))
  out
}

print.results_table <- function(x, digits=4) {
  get_width <- function(data) {
    if (all(is.numeric(data))) {
      data <- format(data, digits=digits)
    }
    max(sapply(as.character(data), nchar))
  }
  col_widths <- sapply(x, get_width)
  titles <- c()
  title_widths <- c()
  for (i in 1:length(x)) {
    if (is.na(pmatch("stars", names(x)[i]))) { # Not a stars column
      titles <- c(titles, names(x)[i])
      title_widths <- c(title_widths, col_widths[i])
    } else {
      # Found a stars column.  Add 4 to the previous title width
      title_widths[length(title_widths)] <- title_widths[length(title_widths)] + 4
    }
    
  }
  
  # Print out titles
  for (i in 1:length(titles)) {
    cat(format(titles[i], width=title_widths[i], justify="centre"))
    cat(" ")
  }
  cat("\n")

  # Print out data 
  for (r in 1:length(x[[1]])) {
    for (i in 1:length(x)) {
      if (is.numeric(x[r,i])) {
        cat(format(x[r,i], digits=digits, width=col_widths[i], justify="right"))
      } else {
        cat(format(x[r,i], width=col_widths[i], justify="left"))
      }
      cat(" ")
    }
    cat("\n")
  }
  cat("---\nSignif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 0.99 '#' 1\n") 
}

latex.results_table <- function(x, digits=4) {
  # Output table head
  cat("\\begin{tabular}{")
  for (i in 1:length(x)) {
    if (is.na(pmatch("stars", names(x)[i]))) { # Not a stars column
      cat("|")
    }
    if (all(is.numeric(x[[i]]))) {
      cat("r")
    } else {
      cat("l")
    }
  }
  cat("|}\n\\hline\n")
  
  # Put together column headers
  titles <- c()
  column_sizes <- c()
  for (i in 1:length(x)) {
    if (is.na(pmatch("stars", names(x)[i]))) { # Not a stars column
      titles <- c(titles, names(x)[i])
      column_sizes <- c(column_sizes, 1)
    } else {
      # Found a stars column.  Add 4 to the previous title width
      column_sizes[length(column_sizes)] <- column_sizes[length(column_sizes)] + 1
    }
  }
  for (i in 1:length(titles)) {
    titles[i] <- paste("\\multicolumn{", column_sizes[i], "}{|c|}{\\emph{", titles[i], "}}", sep="")
  }
  cat(paste(titles, collapse=" & "))
  cat("\\\\\\hline\n")

  # Output data
  for (r in 1:length(x[[1]])) {
    out <- c()
    for (i in 1:length(x)) {
      if (is.numeric(x[r,i])) {
        out <- c(out, format(x[r,i], digits=digits))
      } else {
        out <- c(out, as.character(x[r,i]))
      }
    }
    cat(paste(out, collapse=" & "))
    cat("\\\\\\hline\n")
  }
  # Table footer
  cat("\\end{tabular}\n")
}

csv <- function(x, ...) {
  UseMethod("csv")
}

csv.summary.multiple.del.newfit <- function(x, ...) {
  csv.results_table(results_table(x, URL=strtrim(URL, 30), N=num_users.estimated, onSite=main.effects[2,1], stars=main.effects.stars[2], byUser=main.effects[3,1], stars=main.effects.stars[3], Interact=main.effects[4,1], stars=main.effects.stars[4],
            Gm=Gm, stars.df=Gm.df, stars=stars(Gm.p), 
          "R^2_L"=R2L, #"R^2"=r.squared,
          real_p = calc_real_p(error.table), lambda_p=lambda_p, stars=stars(lambda_p_d_p), ...))
}

csv.results_table <- function(x, digits=4) {
  # Output table head
  
  # Put together column headers
  titles <- c()
  column_sizes <- c()
  for (i in 1:length(x)) {
    if (is.na(pmatch("stars", names(x)[i]))) { # Not a stars column
      titles <- c(titles, names(x)[i])
    } else {
      titles <- c(titles, "sig")
    }
  }
  for (i in 1:length(titles)) {
    titles[i] <- paste("\"", titles[i], "\"", sep="")
  }
  cat(paste(titles, collapse=","))
  cat("\n")

  # Output data
  for (r in 1:length(x[[1]])) {
    out <- c()
    for (i in 1:length(x)) {
      if (is.numeric(x[r,i])) {
        out <- c(out, format(x[r,i], digits=digits))
      } else {
        out <- c(out, as.character(x[r,i]))
      }
    }
    cat(paste(out, collapse=","))
    cat("\n")
  }
}
