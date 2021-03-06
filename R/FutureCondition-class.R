#' A condition (message, warning, or error) that occurred while orchestrating a future
#'
#' While _orchestrating_ (creating, launching, querying, collection)
#' futures, unexpected run-time errors (and other types of conditions) may
#' occur.  Such conditions are coerced to a corresponding FutureCondition
#' class to help distinguish them from conditions that occur due to the
#' _evaluation_ of the future.
#' 
#' @param message A message condition.
#' 
#' @param call The call stack that led up to the condition.
#' 
#' @param future The [Future] involved.
#' 
#' @return An object of class FutureCondition which inherits from class
#' \link[base:conditions]{condition} and FutureMessage, FutureWarning,
#' and FutureError all inherits from FutureCondition.
#' Moreover, a FutureError inherits from \link[base:conditions]{error},
#' a FutureWarning from \link[base:conditions]{warning}, and
#' a FutureMessage from \link[base:conditions]{message}.
#'
#' @export
#' @keywords internal
FutureCondition <- function(message, call = NULL, future = NULL) {
  ## Support different types of input
  if (inherits(message, "condition")) {
    cond <- message
    message <- conditionMessage(cond)
  } else if (is.null(message)) {
    stop("INTERNAL ERROR: Trying to set up a FutureCondition with message = NULL")
  }

  message <- as.character(message)
  if (length(message) != 1L) {
    stop("INTERNAL ERROR: Trying to set up a FutureCondition with length(message) != 1L: ", length(message))
  }
  
  ## Create a condition object
  structure(list(message = message, call = call), 
            class = c("FutureCondition", "condition"),
            future = future)
}


#' @importFrom utils tail
#' @export
print.FutureCondition <- function(x, ...) {
  NextMethod()

  future <- attr(x, "future", exact = TRUE)

  if (!is.null(future)) {
    cat("\n\nDEBUG: BEGIN TROUBLESHOOTING HELP\n")

    if (!is.null(future)) {
      cat("Future involved:\n")
      print(future)
      cat("\n")
    }

    cat("DEBUG: END TROUBLESHOOTING HELP\n")
  }

  invisible(x)
} ## print()



#' @rdname FutureCondition
#' @export
FutureMessage <- function(message, call = NULL, future = NULL) {
  cond <- FutureCondition(message = message, call = call, future = future)
  class(cond) <- c("FutureMessage", "message", class(cond))
  cond
}


#' @rdname FutureCondition
#' @export
FutureWarning <- function(message, call = NULL, future = NULL) {
  cond <- FutureCondition(message = message, call = call, future = future)
  class(cond) <- c("FutureWarning", "warning", class(cond))
  cond
}


#' @rdname FutureCondition
#' @export
FutureError <- function(message, call = NULL, future = NULL) {
  cond <- FutureCondition(message = message, call = call, future = future)
  class(cond) <- c("FutureError", "error", class(cond))
  cond
}


#' @param hint (optional) A string with a suggestion on what might be wrong.
#'
#' @rdname FutureCondition
#' @export
UnexpectedFutureResultError <- function(future, hint = NULL) {
  label <- future$label
  if (is.null(label)) label <- "<none>"
  expr <- hexpr(future$expr)
  result <- future$result
  result_string <- hpaste(as.character(result))
  if (length(result_string) == 0L)
    result_string <- ""
  else if (nchar(result_string) > 512L)
    result_string <- paste(substr(result_string, start = 1L, stop = 512L),
                           "...")
  if (!is.null(hint)) {
    result_string <- if (nzchar(result_string)) {
      sprintf("%s. %s", result_string, hint)
    } else {
      hint
    }
  }
  msg <- sprintf("Unexpected result (of class %s != %s) retrieved for %s future (label = %s, expression = %s): %s",
                 sQuote(class(result)[1]), sQuote("FutureResult"),
                 class(future)[1], sQuote(label), sQuote(expr),
                 result_string)
  cond <- FutureError(msg, future = future)
  class(cond) <- c("UnexpectedFutureResultError", class(cond))
  cond
}
