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
# iua_site.R
# Rick Wash <rwash@umich.edu>
#
# Calculates the inter-user agreement for del.icio.us URLs
#
# - run_site(db, delicious_id, prefix, size=99999)
#   - Calculate the inter-user agreement for a given URL (represented by deliciousID)
#   - prefix is the database table prefix (like "jan2007") for the tables with the data
#   - If size is smaller than the number of users, then choose a subsample of size users 
#     to computer the inter-user agreement for
#
# - run_all_sites(db, prefix, sites, size=99999)
#   - Calculate the inter-user agreement for a set of URLs
#   - same parameters as run_site

get_user_count <- function(u, tag_use) {
#  temp <- subset(tag_use, user==u);
  return(tag_use$count.tag[tag_use$user == u])
#  return(subset(tag_use, user == u, count.tag)$count.tag)
}

interuser_agreement <- function(u1, u2, agreement, tag_use) {
  agree <- agreement[u1,u2]
  tags <- get_user_count(u1, tag_use) + get_user_count(u2, tag_use) - agree
  return(agree / tags)
}

iua_site <- function(agreement, tag_use_cur) {
  user_list <- as.character(tag_use_cur$user)
  agreern <- rownames(agreement)
  agreecn <- colnames(agreement)
  out <- c()
#  out.names <- c()
  for (u1 in user_list) {
    for (u2 in user_list) {
      if (u1 < u2) {
        if ((u1 %in% agreern) && (u2 %in% agreecn)) {
          iua <- interuser_agreement(u1, u2, agreement, tag_use_cur)
          out <- c(out, iua)
        } else if ((u2 %in% agreern) && (u1 %in% agreecn)) {
          iua <- interuser_agreement(u2, u1, agreement, tag_use_cur)
          out <- c(out, iua)
        } else {
          out <- c(out, 0)
        }
#        out.names <- c(out.names, paste(u1, u2, sep=","))
      }
    }
  }
#  names(out) <- out.names
  return(out)
}

sample_query <- function(site, prefix, size, main_table) {
  paste("create table sample (key `user` (`user`), key `tag` (`tag`)) select s.user, t.tag from ", 
                       main_table, " s, ", prefix, "_tag t,", 
                      " (select distinct user from ", 
                       main_table, 
                      " where deliciousID = '",
	               site,
                      "' order by RAND() limit ", 
                       size, 
                      ") i where s.user = i.user and s.id = t.site_id and s.deliciousID = '", site, "'", sep="" )
}

absolute_time_query <- function(site, prefix, start, end) {
   paste("create table temp_time (key `user` (`user`), unique `id` (`id`)) select id, deliciousID, user from ", prefix, "_site s where date >= '", start, "' and date < '", end, 
         "' and deliciousID = '", site, "'", sep="")
}

relative_time_query <- function(site, prefix, start, end) {
  paste("create table temp_time (key `user` (`user`), unique `id` (`id`)) select d.id, d.deliciousID, d.user from ",prefix,"_site d, ",
        "(SELECT min(date) as mindate FROM ",prefix,"_site d where deliciousID = '",site,"') s ",
        "where datediff(d.date, s.mindate) >= ",start," and datediff(d.date, s.mindate) < ",end,
        " and deliciousID = '",site,"'", sep="")
}

position_time_query <- function(site, prefix, start, end) {
   paste("create table temp_time (key `user` (`user`), unique `id` (`id`)) select id, deliciousID, user from ", prefix, "_site s where position >= '", start, "' and position < '", end, 
         "' and deliciousID = '", site, "'", sep="")
}

choose_sample <- function(db, site, prefix, table, size) {
   res <- dbSendQuery(db, sample_query(site, prefix, size, table))
   dbClearResult(res)
   agree_raw <- sqlQuery(db, "select s1.user, s2.user from sample s1, sample s2 where s1.user < s2.user and s1.tag = s2.tag")
   tag_use <- sqlQuery(db, "select user, count(tag) as `count.tag` from sample group by user")
   if (("user" %in% names(agree_raw)) && (length(agree_raw$user) > 0)) {
     agreement <- table(agree_raw)
   } else {
     agreement <- table(data.frame(factor(1), factor(1)))
   }
   avg_tags <- sqlQuery(db, "select avg(num) as avg from (select user, count(tag) as num from sample group by user) a")$avg
   res <- dbSendQuery(db, "drop table sample")
   dbClearResult(res)
   return(list(tag_use = tag_use, agreement = agreement, average=avg_tags))
}

delicious_ids <- function(db, prefix) {
  ids <- sqlQuery(db, paste("select distinct deliciousID from ", prefix, "_site", sep=""))
  return(as.character(ids$deliciousID))
}

run_sample <- function(sample) {
  users <- length(sample$tag_use$user)
  if (users > 1) {
    iua <- iua_site(sample$agreement, sample$tag_use)
    out <- c(users, mean(iua), sd(iua), fivenum(iua), sample$average)
  } else {
    if (users == 1) {
      out <- c(1,NA,NA,NA,NA,NA,NA,NA,NA)
    } else {
      out <- c(0,NA,NA,NA,NA,NA,NA,NA,NA)
    }
  }
  names(out) <- c("Users", "Mean", "SD", "Min", "Q1", "Median", "Q3", "Max", "Num Tags")
  return(out)
}

#run_site <- function(db, site, prefix, size) {
#  sample <- choose_sample(db, site, prefix, paste(prefix, "_site", sep=""), size)
#  return(run_sample(sample))
#}
#
#run_site_query <- function(db, site, prefix, size, query) {
#  sqlQuery(db, query)
#  sample <- choose_sample(db, site, prefix, "temp_time", size)
#  sqlQuery(db, "drop table temp_time")
#  return(run_sample(sample))
#}
#
#run_site_absolute_time <- function(db, site, prefix, size, start, end) {
#  run_site_query(db, site, prefix, size, absolute_time_query(site, prefix, start, end))
#}
#
#run_site_relative_time <- function(db, site, prefix, size, start, end) {
#  run_site_query(db, site, prefix, size, relative_time_query(site, prefix, start, end))
#}
#
#run_site_position_time <- function(db, site, prefix, size, start, end) {
#  run_site_query(db, site, prefix, size, position_time_query(site, prefix, start, end))
#}

run_site <- function(db, site, prefix, size=99999, type = "full", start=NULL, end=NULL) {
  q <- switch(type,
          full = NULL,
          absolute = absolute_time_query(site, prefix, start, end),
          relative = relative_time_query(site, prefix, start, end),
          position = position_time_query(site, prefix, start, end) )
  if (!is.null(q)) {
    sqlQuery(db, q)
    table = "temp_time"
  } else {
    table = paste(prefix, "_site", sep="")
  }
  sample <- choose_sample(db, site, prefix, table, size)
  if (!is.null(q)) {
    sqlQuery(db, "drop table temp_time")
  }    
  return(run_sample(sample))
}

make_data_frame <- function(info) {
  out <- c()
  for (i in names(info)) {
    out <- c(out, info[[i]])
  }
  d <- matrix(out, nrow=length(names(info)), byrow=TRUE, dimnames=list(names(info), names(info[[1]])))
  d2 <- data.frame(d)
}

run_all_sites <- function(db, prefix, size = 99999, sites=NULL, type="full", start=NULL, end=NULL) {
  if (is.null(sites)) {
    sites <- delicious_ids(db, prefix)
  }
  out = list()
  for (s in sites) {
    data <- run_site(db, s, prefix, size, type=type, start=start, end=end)
    out[[s]] <- data
  }
  return(make_data_frame(out))
}

run_site_over_time <- function(db, prefix, site, size=99999, type="absolute", times=NULL,cumulative=FALSE) {
  n <- length(times)
  out <- list()
  for (i in seq(2, n)) {
    if (cumulative) {
      start = times[1]
      end = times[i]
    } else {
      start = times[i-1]
      end = times[i]
    }
    data <- run_site(db, site, prefix, size, type=type, start=start, end=end)
    out[[paste(start, end, sep="-")]] <- data
  }
  return(make_data_frame(out))
}


run_all_sites_over_time <- function(db, prefix, size = 99999, sites=NULL, type="full", times=NULL,cumulative=FALSE) {
  if (is.null(sites)) {
    sites <- delicious_ids(db, prefix)
  }
  out = data.frame()
  for (s in sites) {
    data <- run_site_over_time(db, site=s, prefix=prefix, size=size, type=type, times=times,cumulative=cumulative)
    data$id <- s
    data$date <- row.names(data)
    out <- rbind(out, data)
  }
  out$id <- factor(out$id)
  out$date <- ordered(out$date, levels=out$date[seq(1,length(times)-1)])
  row.names(out) <- paste(out$id, out$date, sep=":")
  return(out)
}

gen_date_range <- function(start_year, start_month, end_year, end_month, by=1) {
  out <- c()
  if (start_year == end_year) {
    temp_end_month = end_month
  } else {
    temp_end_month = 12
  }
  for(m in seq(start_month, temp_end_month, by=by)) {
    if (m < 10) {
      m <- paste("0", m, sep="")
    }
    out <- c(out, paste(start_year, m, "01", sep="-"))
  }    
  if (end_year > start_year) {
    if (end_year > start_year + 1) {
      for (y in seq(start_year + 1, end_year - 1)) {
        for (m in seq(1, 12, by=by)) {
          if (m < 10) {
            m <- paste("0", m, sep="")
          }
          out <- c(out, paste(y, m, "01", sep="-"))
        }
      }
    }
    for(m in seq(1, end_month, by=by)) {
      if (m < 10) {
        m <- paste("0", m, sep="")
      }
      out <- c(out, paste(end_year, m, "01", sep="-"))
    }
  }
  return(out)
}

gen_p2p <- function(db, site) {
  p2p_raw <- sqlQuery(db, paste("select s1.user, s2.user from ", site, " s1, ", site, " s2 where s1.user < s2.user and s1.tag = s2.tag"))
  p2p <- table(p2p_raw)
  return(p2p)
}


calculate_iua <- function(delID, tag_use_info) {
  agreement <- read.csv(paste("p2p/p2p-", delID, ".csv", sep=""), header=TRUE, row.names=1)
  tag_use_cur <- subset(tag_use_info, deliciousID == delID)
  user_list <- as.character(tag_use_cur$user)
  out <- c()
#  out.names <- c()
  for (u1 in user_list) {
    for (u2 in user_list) {
      if (u1 < u2) {
        if ((u1 %in% rownames(agreement)) && (u2 %in% colnames(agreement))) {
          iua <- interuser_agreement(u1, u2, agreement, tag_use_cur)
          out <- c(out, iua)
        } else if ((u2 %in% rownames(agreement)) && (u1 %in% colnames(agreement))) {
          iua <- interuser_agreement(u2, u1, agreement, tag_use_cur)
          out <- c(out, iua)
        } else {
          out <- c(out, 0)
        }
#        out.names <- c(out.names, paste(u1, u2, sep=","))
      }
    }
  }
#  names(out) <- out.names
  return(out)
}

iua <- function(ids, tag_use_info, funs= c("mean", "max", "min", "sd", "median")) {
  temp <- list()
  for (id in ids) {
    info <- calculate_iua(id, tag_use_info)
    temp[[id]] <- info  
  }
  out <- matrix(0, nrow=length(ids), ncol=length(funs))
  rownames(out) <- ids
  colnames(out) <- funs
  for (id in ids) {
    for (f in funs) {
      val <- eval(call(f, temp[[id]]))
      out[id,f] <- val
    }
  }
  return(list(data = temp, stats=out))      
}

gen_relative_days_range <- function(interval_size, interval_count) {
	gaps <- c(0, 27, 58, 88, 119, 149, 180, 211, 241, 272, 302, 333, 364, 392, 423, 453, 484, 514, 545, 576, 606, 637, 667, 698, 729, 757, 788, 818, 849, 879, 910, 941, 971, 1002, 1032, 1063, 1094, 1122, 1153, 1183, 1214, 1244, 1275, 1306, 1336, 1367, 1397, 1428, 1459, 1487, 1518, 1548, 1579, 1609, 1640, 1671, 1701, 1732, 1762, 1793, 1824, 1852, 1883, 1913, 1944, 1974, 2005, 2036, 2066, 2097, 2127, 2158, 2189)
	count <- 0
	elements <- c(1)
	while (count < interval_count) {
		elements <- c(elements, elements[length(elements)] + interval_size)
		count <- count + 1
	}
	out <- gaps[elements]
	return(out)
}
