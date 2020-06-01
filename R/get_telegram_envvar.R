get_telegram_envvar <- function(envvar_prefix){

    f <- function(x){
        envs <- as.list(Sys.getenv())
        if (is.null(x)){
            envs <- envs[grep(paste0("^", envvar_prefix) , names(envs))]
            if (length(envs) > 0L) {
                choices <- gsub(envvar_prefix, '', names(envs))
                choice <- utils::menu(choices = choices,
                                      title = 'Choose one')
                return(envs[[choice]])
            } else
                stop("I didn't found any system variable starting with ",
                     envvar_prefix)
        } else if (is.character(x) && length(x) == 1L) {
            varname <- paste0(envvar_prefix, x)
            ## exact matching (for BOT, USER and GROUP)
            exact_match <- varname %in% names(envs)
            ## try list matching (for PROXY)
            vars_prefix <- paste0(varname, '_')
            list_match <- grep(paste0("^", vars_prefix), names(envs))
            if (exact_match) {
                return(envs[[varname]])
            } else if (any(list_match)) {
                ## extract the list
                select <- envs[list_match]
                ## remove name prefix
                names(select) <- gsub(vars_prefix, "", names(select))
                return(select)
            } else
                stop(varname, ' (starting) environment variable (s) is (are) not available.')
        } else
            stop('x must be a length 1 char or NULL')
    }

    return(f)
}

#' bot_token
#'
#' Obtain token from system variables (in \code{Renviron}) set
#' according to package naming conventions, that is
#' \code{R_TELEGRAM_BOT_} where \code{X} is bot's name (first question
#' answered to the botfather).
#'
#' @param x character of length 1 with the name of the bot; if
#'     \code{NULL} a menu to choose between bot is displayed and the
#'     proper value returned
#' @examples \dontrun{ bot_token('RBot') }
#' @export
bot_token <- get_telegram_envvar('R_TELEGRAM_BOT_')

#' user_id
#'
#' Obtain telegram user id from system variables (in \code{Renviron}) set
#' according to package naming conventions, that is
#' \code{R_TELEGRAM_USER_X} where is the user's name .
#'
#' @param x character of length 1 with the name of the user; if
#'     \code{NULL} a menu to choose between bot is displayed and the
#'     proper value returned
#' @examples \dontrun{ user_id('me') }
#' @export
user_id <- get_telegram_envvar('R_TELEGRAM_USER_')

#' group_id
#'
#' Obtain telegram user id from system variables (in \code{Renviron}) set
#' according to package naming conventions, that is
#' \code{R_TELEGRAM_USER_X} where is the user's name .
#'
#' @param x character of length 1 with the name of the user; if
#'     \code{NULL} a menu to choose between bot is displayed and the
#'     proper value returned
#' @examples \dontrun{ group_id('test_group') }
#' @export
group_id <- get_telegram_envvar('R_TELEGRAM_GROUP_')


#' proxy
#'
#' Obtain telegram proxy from system variables (in \code{Renviron}) set
#' according to package naming conventions, that is
#' \code{R_TELEGRAM_PROXY_X_Y} where X is the proxy's name and Y are the
#' proxy parameters.
#'
#' @param x character of length 1 with the name of the proxy; if
#'     \code{NULL} a menu to choose between proxy is displayed and the
#'     proper value returned
#' @examples \dontrun{ proxy('default') }
#' @export
proxy <- get_telegram_envvar('R_TELEGRAM_PROXY_')
