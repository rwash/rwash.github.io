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
# montecarlo.R
# Rick Wash <rwash@umich.edu>
#
# This is the code for the monte carlo simulations (computer models) of del.icio.us
# 
# The main function is:
#  generate_set(db, ids=NULL, rep=1)
#  - Generate 5 sites (one for each condition) matched with each site in ids
#  - if ids is null, get the id list from the database
#  - rep is the number of repetitions.  I did 4 for the paper
#
# Look at the conf.* functions for the initial config for the 5 conditions:
# - unbiased     <=> Zipf
# - recommended  <=> Imitation - Popular
# - urn          <=> Imitation - Urn
# - user         <=> Organizing
# - onsite       <=> Imitation - Random

# Simulation Code

# To use:
# ** First you need to generate a configuration for the "type" of site you want:
# conf <- mcconfig(tag_type)
# - tag_type="simple": Generate an "average" site -- use the average parameter estimates
#                      (uses the estimated mean parameter values for distributions)
# - tag_type="normal": (default) Genrate random parameters and then use those to generate a 
#                  site.   You'll get different types of sites this way.
#                  (uses both estimated mean and standard deviation values for distributions)
# - tag_type="corrected": Same as normal, except increase the alpha parameter to compensate for 
#                     the fact that tags are chosen without replacement for a single user.
#                     (It is unknown if the correction helps.  I was just seeing too low numbers)
#
# conf <- add_users(conf, range, types, weights)
# - range: Length-2 vector containing start and end values for the range of positions these 
#          users are valid for.  E.g.  c(1,50)   NA for either value means the rest of the 
#          positions in that direction.  Defaults to c(NA, NA), meaning all positions
# - types: A list of strings containing the type of user.  OR, instead of a string, a list
#          with parameter "type" containing the type of user and other values to be passed
#          into the generate_tags routine.  
#          E.g. list("unbiased", "topN", list(type="recommended", N=10))
#          Possible types:
#          - "unbiased": User chooses tags randomly according to the specified distribution
#          - "topN": If the user wants to choose N tags, he chooses the top N most used tags
#          - "proportional": Choose a tag proportionally from the existing tag distribution. 
#                            Treats the existing tags as an empirical CDF and chooses from that.
#          - list(type="recommended", N=<num>):
#              Pretend the system recommended <num> tags to the user.   The user then would choose
#              his tags randomly (uniformly) from that set of tags.
# - weights: Relative weights when randomly choosing user type.  Need not sum to 1.  Defaults
#            to all types are equiprobable.  E.g. c(1,2,3) would choose the 1st type 16.6% 
#            of the time, the 2nd type 33.3% of the time, and the 3rd type 50% of the time.
# Note: You can call add_users as many times as you want, specifying different ranges each time.
#       Do not overlap ranges -- there is no checking if you do, and behavior is unspecified
#
# ** Now, you can generate the site
# generate_site(N, conf)
# - N: The total number of users in the site.  (Should this be part of the configuration?)
#
#
# Sample usage:
# - The first 50 users choose tags randomly.
# - The remaining users are 1 of 3 types:
#   - Unbiased (20%) - choose tags randomly
#   - TopN (40%) - Choose the top N tags
#   - Recommended (40%) - The system recommends the top 10 tags and the user chooses randomly (uniform) from those
# conf <- mcconfig("normal")
# conf <- add_users(conf, c(NA, 50), "unbiased")
# conf <- add_users(conf, c(51, NA), c("unbiased", "topN", list(type="recommended", N=10)), weights=c(1,2,2))
# data <- generate_site(150, conf)

# Generate tags for a single user
generate_tags.unbiased <- function(n, conf, ...) { 
  random.sample(n, conf$tag.dist)
}

generate_tags.topN <- function(n, conf, existing_tags, ...) {
  tag_dist <- tapply(existing_tags, existing_tags, length)
  tag_dist <- sort(tag_dist, dec=T)
  tags <- names(tag_dist)[1:n]
  tags
}

generate_tags.recommended <- function(n, conf, existing_tags, N, ...) {
  tag_dist <- tapply(existing_tags, existing_tags, length)
  tag_dist <- sort(tag_dist, dec=T)
  rec_tags <- as.numeric(names(tag_dist)[1:N])
  if (N < n) {
    tags <- as.numeric(names(tag_dist)[1:N])
    while(length(tags) < n) {
      tags <- unique(c(tags, random.sample(1, conf$tag.dist)))
    }
  } else {
    tags <- sample(rec_tags, n)   # Randomly choose n tags from the N recommended tags
  }
  tags
}

generate_tags.proportional <- function(n, conf, existing_tags, existing_tag_names=NULL, ...) {
  tag_dist <- tapply(existing_tags, existing_tags, length)
  tag_dist <- tag_dist / sum(tag_dist)
  if (length(tag_dist) >= n) {
    tags <- sample(names(tag_dist), n, prob=tag_dist)
    return(as.numeric(tags))
  } 
  # Too few tags to empirically choose from...  Generate from tag.dist
  tags <- as.numeric(names(tag_dist))
  while (length(tags) < n) {
    tags <- unique(c(tags, random.sample(1, conf$tag.dist)))
  }
  tags
}

generate_tags.onsite <- function(n, conf, existing_tags, existing_tag_names=NULL, ...) {
  tag_dist <- tapply(existing_tags, existing_tags, length)
  tag_dist <- tag_dist / sum(tag_dist)
  if (length(tag_dist) >= n) {
    tags <- sample(names(tag_dist), n)  # Note, don't specify proabilities. Chosen uniformly.
    return(as.numeric(tags))
  } 
  # Too few tags to empirically choose from...  Generate from tag.dist
  tags <- as.numeric(names(tag_dist))
  while (length(tags) < n) {
    tags <- unique(c(tags, random.sample(1, conf$tag.dist)))
  }
  tags
}

generate_tags.user_biased <- function(n, conf, existing_tags, all_tags=NULL, username=NULL, existing_tag_names=NULL, db=NULL, ...) {
  # Needs logistic.R loaded
  tag_nums <- c()
  user_tag_info <- get_tag_history(db, username)  
  if (length(user_tag_info) > 0) {
    user_tags <- names(sort(tapply(user_tag_info$tag, user_tag_info$tag, length), dec=T))
    overlap <- user_tags[user_tags %in% all_tags] 
    # If there are enough tags from the user, return those
    if (length(overlap) > 0) {
      tag_nums <- which(all_tags %in% overlap[1:min(n, length(overlap))])
    } 
    if (length(tag_nums) >= n) {
      return(tag_nums)
    }
  }
  # If we get here, we need to generate more tags.
  while(length(tag_nums) < n) {
    # Add a newly generated tag to the list
    tag_nums <- unique(c(tag_nums, random.sample(1, conf$tag.dist)))
  }
  tag_nums
}

new_tag <- function(existing_tags) {
  i <- 1
  tag_list <- unique(existing_tags)
  while (i %in% tag_list) {
    i <- i + 1
  }
  i
}

generate_tags <- function(n, conf, existing_tags, pnew = 0, ..., type="unbiased") {
  gt.name <- paste("generate_tags.", type, sep="")
  if (exists(gt.name))
    gt <- get(gt.name)
  else
    stop(paste("I don't know how to generate tags of type", type))
  tags <- c()
  if (runif(1,0,1) <= pnew) {
    tags <- new_tag(existing_tags)
    n <- n-1
  }
  tags <- c(tags, gt(n, conf, existing_tags, ...))
  tags
}

get_user_type <- function(pos, choice_list) {
  for (c in choice_list) {
    if (in_range(pos, c$range))
      return(c)
  }
}

generate_user <- function(conf, pos, ...) {
  num.tags <- random(1, conf$num.tags)
  uc <- get_user_type(pos, conf$user.choices)
  r <- runif(1,0,1)
  i <- which(r < cumsum(uc$probs))[1]
  type <- uc$users[[i]]
  params <- NULL
  if (is.list(type)) {
    params <- type
    type <- type$type
    params$type <- NULL # Remove type from the params
  }
  list(type=type, num.tags=num.tags, params=params)
}

# Generate tags for a whole site
# Default alpha is the mean estimated alpha for the jan2007 sample
# Default xmin is the mean estimated xmin for the jan2007 sample
generate_site <- function(conf) {
   pos <- numeric(0)
   tag <- numeric(0)
   type <- character(0)
   num_users <- conf$N
   for (s in 1:num_users) {
      # Choose how many tags for this user
      user <- generate_user(conf, s)     
      if (user$num.tags == 0)
        warning("Error -- num.tags == 0")
      
      pos <- c(pos, rep(s, user$num.tags))
      type <- c(type, rep(user$type, user$num.tags))
#      new_tags <- generate_tags(user$num.tags, conf, type=user$type, existing_tags=tag)
      new_tags <- do.call("generate_tags", c(list(n=user$num.tags, conf=conf, existing_tags=tag, type=user$type), user$params))
      tag <- c(tag, new_tags)
   }
   out <- data.frame(position = pos, tag = factor(tag), type=type)
   class(out) <- c("mc_site", class(out))
   attr(out, "config") <- conf
   out
}

generate_matched_site <- function(db, conf, id=NULL, prefix="jan2007") {
  if (is.null(id)) {
    id <- sqlQuery(db, paste("select deliciousID from (select distinct deliciousID from ids) s order by RAND() limit 1", sep=""))
    id <- id[['deliciousID']]
  }
  real_data <- site_data(db, id)
  real_data$tag <- factor(real_data$tag)

  # Use conf$N if less than the number of users in the real site
  num_users <- min(conf$N, length(unique(as.character(real_data$user))))
  conf$N <- num_users

  tag.info <- tapply(real_data$tag, real_data$tag, length)
  top.tags <- names(sort(tag.info, dec=T))
  user_list <- sample(unique(as.character(real_data$user)), num_users)

  pos <- c()
  type <- c()
  users <- c()
  tag_nums <- c()
  tag_names <- c()
  # Loop through and generate users.   Mostly copied from generate_site
  for (s in 1:num_users) {
    user <- generate_user(conf, s)
    user$username <- user_list[s]
    if (user$num.tags == 0)
      warning("Error -- num.tags == 0")
    
    # Append data to columns
    pos <- c(pos, rep(s, user$num.tags))
    type <- c(type, rep(user$type, user$num.tags))
    users <- c(users, rep(user$username, user$num.tags))
    # Generate new tags
    new_tags <- do.call("generate_tags", c(list(n=user$num.tags, conf=conf, existing_tags=tag_nums, username=user$username, existing_tag_names=tag_names, all_tags=top.tags, db=db, type=user$type), user$params))
    new_tag_names <- ifelse(new_tags > length(top.tags), new_tags, top.tags[new_tags])
    # Append tags to columns
    tag_nums <- c(tag_nums, new_tags)
    tag_names <- c(tag_names, new_tag_names)
  }

  out <- data.frame(position = pos, tag = factor(tag_names), type=type, user=users, tag_nums=factor(tag_nums))
  class(out) <- c("mc_site", class(out))
  attr(out, "config") <- conf
  attr(out, "real_id") <- id
  out
}

save_site <- function(db, data, site_id, type, prefix="mc") {
  real_id <- attr(data, "real_id")
  sqlInsert(db, paste("insert into ", prefix, "_info (fake_deliciousID, real_deliciousID, user_type) values ('", site_id, "', '", real_id, "', '", type, "')", sep=""))
  # Loop through positions
  for (p in 1:max(data$position)) {
    user_data <- subset(data, position==p)
    username <- as.character(user_data$user[1])
    sqlInsert(db, paste("insert into ", prefix, "_site (deliciousID, user, position) VALUES ('", site_id, "', '", sub("'", "''", username), "', ", p, ")", sep=""))
    last_id <- sqlQuery(db, "select LAST_INSERT_ID()")
    last_id <- last_id[[1]][1]
    # Loop through and add the tags
    for (tag_pos in 1:length(user_data$tag)) {
      sqlInsert(db, paste("insert into ", prefix, "_tag (site_id, tag, position) VALUES (", last_id, ", '", sub("'", "''", as.character(user_data$tag)[tag_pos]), "', ", tag_pos, ")", sep=""))
    }
  }
}

# mcconfig is a data struction containing all the necessary configuration parameters
#  for a run of the monte carlo generator
# randinfo is a data structure for a type of random number

randinfo <- function(dist, params, ...) {
  out <- list(dist=dist, params=params, dots=...)
  class(out) <- c("randinfo", "list")
  out
}

print.randinfo <- function(x, ...) {
  cat(paste(x$dist, "(", paste(c(x$params, x$dots), collapse=","), ")\n", sep=""))
}

randinfo.numtags.default <- function() {
#   * disclnorm 
#     - meanlog: 0.824073727104055 +- 0.454489864656875
#     - sdlog: 0.475836488317795 +- 0.129929430171246
  meanlog <- rnorm(1, 0.824073727104055, 0.454489864656875)
  while (meanlog <= 0.0)
    meanlog <- rnorm(1, 0.824073727104055, 0.454489864656875)
  sdlog <- rnorm(1, 0.475836488317795, 0.129929430171246)
  while (sdlog <= 0.0)
    sdlog <- rnorm(1, 0.475836488317795, 0.129929430171246)
  randinfo("disclnorm", c(meanlog, sdlog))
}

randinfo.tagdist.default <- function() {
#   * dpowerlaw 
#     - alpha: 1.91929524285818 +- 0.401634201492522
  alpha <- rnorm(1, 1.91929524285818, 0.401634201492522)
  while (alpha <= 1.0)
    alpha <- rnorm(1, 1.91929524285818, 0.401634201492522)
  randinfo("dpowerlaw", c(alpha, 1))
}

# Routines for specifying how to choose users
in_range <- function(x, r=c(NA, NA)) {
  if (length(r) != 2)
    stop("Incorrent length in range")
  if (is.na(r[1]) & is.na(r[2]))
    return(rep(T, length(x)))
  if (is.na(r[1]))
    return(x <= r[2])
  if (is.na(r[2]))
    return(x >= r[1])
  return((x <= r[2]) & (x >= r[1]))
}

# User_choice structure.  Specifies how to choose users
# - probs: Vector of probabilities.  Must sum to 1.  Defaults to equi-probable
# - users: List of types of users.  Either a string (type of user) or a list containing a "type" field.
# - range: length-2 vector containing starting and ending position value (inclusive) for which this user choice structure is valid.
user_choice <- function(types, weights=rep(1, length(types)), r=c(NA, NA)) {
  if (length(types) != length(weights))
    stop("Different numbers of types and weights")
  if (length(r) != 2)
    stop("Invalid Range")
  weights <- weights / sum(weights)
  types <- lapply(types, c)    # Convert to a list if necessary
  out <- list(probs=weights, users=types, n=length(weights), range=r)
  class(out) <- c("user_choice", "list")
  out
}

print.user_choice <- function(x, digits=3, ...) {
  if (is.na(x$range[1]) & is.na(x$range[2]))
    cat("Users will be chosen by:\n")
  else if (is.na(x$range[1]))
    cat("For positions less than ", x$range[2], ", users will be chosen by:\n", sep="")
  else if (is.na(x$range[2]))
    cat("For positions after ", x$range[1], ", users will be chosen by:\n", sep="")
  else
    cat("For positions between ", x$range[1], " and ", x$range[2], ", users will be chosen by:\n", sep="")

  for (i in 1:x$n) {
    if (is.list(x$users[[i]])) {
      cat(formatC(x$probs[i]*100, digits=digits), "% - ", x$users[[i]][['type']], sep="")
      tlist <- list()
      for (n in names(x$users[[i]])) {
        if (n == "type") next      # Skip the type field
        if (n == "pnew") next      # Skip the pnew field
        tlist[[n]] <- x$users[[i]][[n]]
      }
      if (length(tlist) > 0) {
        cat(" (", paste(names(tlist), "=", tlist, sep="", collapse=","), ")\n", sep="")
      } else { cat("\n") }
      if ("pnew" %in% names(x$users[[i]])) {
        cat("   * Probability of a novel tag == ", x$users[[i]][["pnew"]]*100, "%\n", sep="")
      }
    }
    else
      cat(formatC(x$probs[i]*100, digits=digits), "% - ", x$users[[i]], "\n", sep="")
  }
}


# Use the distributions estimated empirically
# with parameters chosen from a normal distribution
mcconfig.normal <- function() {
  out <- list(num.tags = randinfo.numtags.default(), tag.dist = randinfo.tagdist.default())
  class(out) <- c("mcconfig", "list")
  out
}

# Use the distributions estimated empirically with the mean parameters
mcconfig.simple <- function() {
  numtags <- randinfo("disclnorm", c(0.82, 0.47))
  tags <- randinfo("dpowerlaw", c(1.92, 1))
  out <- list(num.tags = numtags, tag.dist = tags)
  class(out) <- c("mcconfig", "list")
  out
}

# Increase the default alpha coefficients for tag choices to compensate for multiple choices without replacement
mcconfig.corrected <- function() {
  alpha <- rnorm(1, 2.5, 0.40163)
  while(alpha <= 1.0)
    alpha <- rnorm(1, 2.5, 0.40163)
  out <- list(num.tags = randinfo.numtags.default(), tag.dist = randinfo("dpowerlaw", c(alpha, 1)))
  class(out) <- c("mcconfig", "list")
  out
}

mcconfig <- function(type=c("normal", "simple", "corrected"), num.tags=NULL, tag.dist=NULL, N=NULL) {
  type <- match.arg(type)
  f <- get(paste("mcconfig.", type, sep=""))
  out <- f()
  if (!is.null(num.tags))
    out$num.tags <- num.tags
  if (!is.null(tag.dist))
    out$tag.dist <- tag.dist
  out$user.choices <- list()
  if (is.null(N)) {
    out$N <- round(rlnorm(1, 6.10836380113702, 1.06793421929557))
  } else {
    out$N <- N
  }
  out
}

print.mcconfig <- function(x, ...) {
  cat("Number of Users: ", x$N, "\n")
  cat("Distribution for Number of Tags per bookmark:\n  ")
  print(x$num.tags)
  cat("Distribution of individual tags:\n  ")
  print(x$tag.dist)
  for (c in x$user.choices)
    print(c)
}

add_users <- function(conf, r, types, weights=rep(1, length(types))) {
  choice <- user_choice(types, weights, r)
  conf$user.choices <- c(conf$user.choices, list(choice))
  conf
}

# Full configurations for montecarlo runs
conf.unbiased <- function(type="corrected") {
  conf <- mcconfig(type)
  conf <- add_users(conf, c(NA, NA), "unbiased")
  conf
}

conf.recommended <- function(num.recommended = 5, seeds=20, type="corrected") {
  conf <- mcconfig(type)
  conf <- add_users(conf, c(NA, seeds), "unbiased")
  conf <- add_users(conf, c(seeds+1, NA), list(list(type="recommended", N=num.recommended)))
  conf
}

# > pnew_all <- sapply(ids, function(id) { d <- site_data(con, id); mean(pnew(d, "raw")$data)})
# > mean(pnew_all)
# [1] 0.1045940
conf.urn <- function(pnew = 0.10, seeds=20, type="corrected") {
  conf <- mcconfig(type)
  conf <- add_users(conf, c(NA, seeds), "unbiased")
  conf <- add_users(conf, c(seeds+1, NA), list(list(type="proportional", pnew=pnew)))
  conf
}

conf.user <- function(type="corrected") {
  conf <- mcconfig(type)
  conf <- add_users(conf, c(NA, NA), c("user_biased", "unbiased"))
  conf
}

conf.onsite <- function(pnew=0.10, seeds=20, type="corrected") {
  conf <- mcconfig(type)
  conf <- add_users(conf, c(NA, seeds), "unbiased")
  conf <- add_users(conf, c(seeds+1, NA), list(list(type="onsite", pnew=pnew)))
  conf
}

generate_everything <- function(db, id = NULL, type = c("unbiased", "recommended", "urn", "user", "onsite"), prefix="mc", ...) {
  type <- match.arg(type)
  cat("Simulating", type, "matched with deliciousID", id, "\n")
  conf_func <- get(paste("conf.", type, sep=""))
  conf <- conf_func(...)
  data <- generate_matched_site(db, conf, id=id)
  ids <- sqlQuery(db, paste("select distinct deliciousID from ", prefix, "_site", sep=""))
  if (length(ids) == 0) {
    next_id <- 1
  } else {
    next_id <- max(as.numeric(ids[[1]]))+1
  }
  save_site(db, data, next_id, type, prefix=prefix)
  next_id
}

generate_set <- function(db, ids = NULL, types = c("unbiased", "recommended", "urn", "user", "onsite"), rep=1, prefix="mc") {
  if (is.null(ids)) {
    ids <- unique(as.character(sqlQuery(db, "select deliciousID from ids")$deliciousID))
  }
  cat("Generating", rep * length(types) * length(ids), "sites total\n")
  for (r in 1:rep) {
    cat("Starting Repetition", r, "\n")
    for (i in ids) {
      for (t in types) {
        generate_everything(db, id=i, type=t, prefix=prefix)
      }
    }
  }
}

# Routines for choosing random numbers according to a randinfo struct
random <- function(n, ri) {
  if (!any("randinfo" %in% class(ri)))
    stop("Invalid RandInfo structure")
  fname <- paste("r", ri$dist, sep="")
  if (!exists(fname))
    stop(paste("Cannot find random number generator for", ri$dist))
  out <- do.call(fname, c(list(n=n), as.list(ri$params), ri$dots))
  while (any(out == 0))
    out <- do.call(fname, c(list(n=n), as.list(ri$params), ri$dots))
  out
}

random.sample <- function(n, ri) {
  out <- c()
  count <- 0
  while (length(out) < n) {
    out <- unique(c(out, random(1, ri)))
    count <- count + 1
  }
#  cat(paste("It took", count, "iterations\n"))
  out
}


# Not exact, but not that far off I hope.....
rdisclnorm <- function(n, meanlog, sdlog, ...) {
  round(rlnorm(n, meanlog, sdlog, ...))
}

# # Empirical best fit for tag distribution of a user:
# Best fitting distribution(s): dpowerlaw 
#   binom: 0
#   pois: 0
#   disclnorm: 20
#   nbinom: 0
#   dpowerlaw: 142
#   geom: 0
#   discexp: 0
#   Undetermined: 31 
# 
# Paremeter Estimates:
#   * binom 
#     - n: 14.4 +- 13.8098193728633
#     - p: 0.21772918711277 +- 0.164464198407106
#   * pois 
#     - lambda: 6.76669443749605 +- 11.4034298861213
#   * disclnorm 
#     - meanlog: 0.798770507265504 +- 0.52421195024142
#     - sdlog: 0.995245706712871 +- 0.278355249058155
#   * nbinom 
#     - size: 2.27868852459016 +- 7.87079274853316
#     - p: 0.253970521551145 +- 0.194266286247562
#   * dpowerlaw 
#     - alpha: 1.91929524285818 +- 0.401634201492522
#   * geom 
#     - prob: 0.205637707527594 +- 0.100623598927878
#   * discexp 
#     - lambda: 0.238614491159052 +- 0.131837820914414
# NULL
# 
# 
# # Empirical best fit for tag distribution of number of tags chosen at a time
# Best fitting distribution(s): disclnorm 
#   binom: 9
#   pois: 1
#   disclnorm: 126
#   nbinom: 3
#   dpowerlaw: 9
#   geom: 0
#   discexp: 0
#   Undetermined: 42 
# 
# Paremeter Estimates:
#   * binom 
#     - n: 10.9635036496350 +- 12.3362263983693
#     - p: 0.306390826586750 +- 0.122929718058335
#   * pois 
#     - lambda: 2.86668011030925 +- 1.42838002555380
#   * disclnorm 
#     - meanlog: 0.824073727104055 +- 0.454489864656875
#     - sdlog: 0.475836488317795 +- 0.129929430171246
#   * nbinom 
#     - size: 21.8541666666667 +- 20.8224404146751
#     - p: 0.734133079229975 +- 0.187534184482586
#   * dpowerlaw 
#     - alpha: 2.04741640554566 +- 0.75270723299477
#   * geom 
#     - prob: 0.290807572311168 +- 0.0954533579112316
#   * discexp 
#     - lambda: 0.353110006605119 +- 0.139990277958032
# 
#  round(rlnorm(n, meanlog, sdlog))


# # Empirical best fit for the number of users in a site (for our (biased) sample)
# Best fitting distribution(s): lnorm 
# Empirical Data Fit to a distribution:
#   lnorm(meanlog=6.10836380113702,sdlog=1.06793421929557)

# Upon loading...
if (require(RODBC)) {
  sqlInsert <- function(db, q) {
    sqlQuery(db, q)
  }
} else {
  sqlInsert <- function(db, q) {
    res <- dbSendQuery(db, q)
    dbClearResult(res)
  }
}
