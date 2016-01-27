get_telegram_envvar <- function(envvar_prefix){

    f <- function(x){
        if (is.null(x)){
            envs <- as.list(Sys.getenv())
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
            value <- Sys.getenv(varname)
            if (!identical(value, ''))
                return(value)
            else
                stop(varname, ' environment variable is not available.')
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
#'     proper token returned
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
#'     proper token returned
#' @examples \dontrun{ user_id('me') }
#' @export

#' @export
user_id <- get_telegram_envvar('R_TELEGRAM_USER_')
