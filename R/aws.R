# For example, turn profile = "dbconnect" into --profile dbconnect
format_args <- function(...) {
  # interleave arguments
  args <- list(...)

  args <- Filter(function(x) !is.null(x), args)

  if (length(args) == 0) {
    return(NULL)
  }

  if (any(names(args) == "")) {
    stop("All extra arguments must be named")
  }

  c(rbind(paste0("--", names(args)), unlist(args)))
}

#' Get an AWS parameter
#'
#' @param name Name of parameter to retrieve
#' @param ... Additional arguments to pass to aws. For example, \code{profile = "dbconnect"}.
#' @importFrom jsonlite fromJSON
get_parameter <- function(name, ...) {
  msg <- sprintf("Fetching %s from EC2 parameter store", name)
  message(msg)

  additional_args <- format_args(...)

  resp <- system2("aws", args = c("ssm", "get-parameter", "--with-decryption", "--name", name, additional_args), stdout = TRUE)
  fromJSON(paste(resp, collapse = "\n"))$Parameter$Value
}

#' Get AWS parameters
#'
#' @param names Names of parameter to retrieve as a character vector
#' @param ... Additional arguments to pass to aws. For example, \code{profile = "dbconnect"}.
#' @importFrom jsonlite fromJSON
get_parameters <- function(names, ...) {
  msg <- sprintf("Fetching %s... from EC2 parameter store", names[1])

  n <- paste0('"', names, '"', collapse = " ")

  additional_args <- format_args(...)

  message(msg)
  resp <- system2("aws", args = c("ssm", "get-parameters", "--with-decryption", "--names", names, additional_args), stdout = TRUE)
  fromJSON(paste(resp, collapse = "\n"))
}

aws_get_caller_identity <- function(){
  cmd <- 'aws'
  args <- c('--profile', 'dbconnect', 'sts', 'get-caller-identity')
  identity <- system2(cmd, args, stdout = TRUE)
  jsonlite::fromJSON(identity)
}

aws_get_user <- function(){
  identity <- aws_get_caller_identity()
  strsplit(identity$UserId, "\\:")[[1]][2]
}

aws_get_credentials <- function(user){
  user <- aws_get_user()
  cmd <- 'aws'
  args <- c(
    '--profile', 'dbconnect',  'redshift', 'get-cluster-credentials',
    '--cluster-identifier', 'datalake-redshift-public-prod',
    '--db-user', user, '--auto-create', '--db-groups',  'iam',
    'readonlyusers'
  )
  creds <- system2(cmd, args, stdout = TRUE)
  jsonlite::fromJSON(creds)
}
