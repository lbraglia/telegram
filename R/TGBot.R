## ------
## UTILS
## ------

self    <- 'shut up R CMD CHECK'
private <- 'shut up R CMD CHECK'
not_implemented <- function() stop('Currently not implemented')

initialize <- function(token) {
    self$set_token(token)
}

set_token <- function(token){
    if (!missing(token))
        private$token <- token
}

set_default_chat_id <- function(chat_id){
    if (!missing(chat_id))
        private$default_chat_id <- as.character(chat_id)
}

make_body <- function(...){
    body <- list(...)
    body <- body[!unlist(lapply(body, is.null))]
    body
}

request <- function(method, body){
    if (missing(body))
        body <- NULL
    api_url <- sprintf('https://api.telegram.org/bot%s/%s',
                       private$token,
                       method)
    r <- httr::POST(url = api_url, body = body)
    httr::warn_for_status(r)
    r
}

make_methods_string <- function(meth, incipit){
    wrap_at <- 72
    meth_string <- paste0(incipit, '\n',  paste(meth, collapse = ", "))
    paste0(paste(strwrap(meth_string, width = wrap_at),
                 collapse = '\n'),
           '\n')
}

tgprint <- function(){
    obj <- objects(self)
    api_methods <- c("getMe",
                     "sendMessage",
                     "forwardMessage",
                     "sendPhoto",
                     "sendAudio",
                     "sendDocument",
                     "sendSticker",
                     "sendVideo",
                     "sendVoice",
                     "sendLocation",
                     "sendChatAction",
                     "getUserProfilePhotos",
                     "getUpdates",
                     "setWebhook",
                     "getFile")
    dont_show <- c("clone", "initialize", "print")
    avail_methods <- sort(api_methods[api_methods %in% obj])
    remaining_methods <- sort(obj[! obj %in% avail_methods])
    remaining_methods <- remaining_methods[!(remaining_methods %in% dont_show)]
    api_string <- make_methods_string(avail_methods, "API methods: ")
    remaining_string <- make_methods_string(remaining_methods,
                                            "Other methods: ")
    cat("<TGBot>\n\n")
    if (!is.null(private$bot_first_name))
        cat(sprintf('Bot name:\t%s\n', private$bot_first_name))
    if (!is.null(private$bot_first_name))
        cat(sprintf('Bot username:\t%s\n\n', private$bot_username))
    cat(api_string, '\n')
    cat(remaining_string, '\n')
}

check_chat_id <- function(chat_id){
    if (is.null(chat_id)){
        if (is.null(private$default_chat_id))
            stop("chat_id can't be missing")
        else
            return(private$default_chat_id)
    } else
        return(chat_id)
}

check_param <- function(param, type, required = FALSE){
    char_name <- deparse(substitute(char))
    coerce <- c('char'      = as.character,
                'int'       = as.integer,
                'log'       = as.logical,
                'float'     = as.numeric)
    if(is.null(param)){
        if (required) stop(char_name, " can't be missing.")
        else NULL
    }
    else coerce[[type]](param[1])
}

check_file <- function(path, required = FALSE){
    if (file.exists(path))
        path
    else {
        if (required) stop(path, 'is not a valid path')
        else NULL
    }
}

## ------
## TG API
## ------

forwardMessage <- function(from_chat_id = NULL,
                           message_id = NULL,
                           chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    from_chat_id <- check_param(from_chat_id, 'char', required = TRUE)
    message_id <- check_param(message_id, 'char', required = TRUE)
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'from_chat_id' = from_chat_id,
                      'message_id' = message_id)
    ## request
    r <- private$request('forwardMessage', body = body)
    ## response handling
    invisible(r)
}

getFile <- function() not_implemented()

getMe <- function()
{
    r <- private$request('getMe')
    status <- httr::status_code(r)
    if (status == 200){
        c <- httr::content(r)
        private$bot_first_name <- c$result$first_name
        private$bot_username <- c$result$username
        cat(sprintf('Bot name:\t%s\nBot username:\t%s\n',
                    private$bot_first_name,
                    private$bot_username))
    } 
    invisible(r)
}


getUpdates <- function(){
    r <- private$request('getUpdates')
    if (r$status == 200){
        ## parse output (return a data.frame)
        rval <- httr::content(r)$result
        do.call(rbind, lapply(rval, as.data.frame))
    }
    else
        invisible(NULL)
}

getUserProfilePhotos <- function() not_implemented()

sendAudio <- function(audio = NULL,
                      duration = NULL,
                      performer = NULL,
                      title = NULL,
                      reply_to_message_id = NULL,
                      chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    audio <- check_file(audio, required = TRUE)
    duration <- check_param(duration, 'int')
    performer <- check_param(performer, 'char')
    title <- check_param(title, 'char')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'audio' = httr::upload_file(audio),
                      'duration' = duration,
                      'performer' = performer,
                      'title' = title,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendAudio', body = body)
    ## response handling
    invisible(r)
}

sendChatAction <- function() not_implemented()

sendDocument <- function(document = NULL,
                         reply_to_message_id = NULL,
                         chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    document <- check_file(document, required = TRUE)
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'document' = httr::upload_file(document),
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendDocument', body = body)
    ## response handling
    invisible(r)
}

sendLocation <- function(latitude = NULL,
                         longitude = NULL,
                         reply_to_message_id = NULL,
                         chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    latitude <- check_param(latitude, 'float', required = TRUE)
    longitude <- check_param(longitude, 'float', required = TRUE)
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'latitude' = latitude,
                      'longitude' = longitude,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendLocation', body = body)
    ## response handling
    invisible(r)
}

sendMessage <- function(text = NULL,
                        parse_mode = NULL,
                        disable_web_page_preview = NULL,
                        reply_to_message_id = NULL,
                        chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    text <- check_param(text, 'char', required = TRUE)
    parse_mode <- check_param(parse_mode, 'char')
    disable_web_page_preview <- check_param(disable_web_page_preview, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'text' = as.character(text),
                      'parse_mode' = parse_mode,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendMessage', body = body)
    ## response handling
    invisible(r)
}

sendPhoto <- function(photo = NULL,
                      caption = NULL,
                      reply_to_message_id = NULL,
                      reply_markup = NULL,
                      chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    photo <- check_file(photo, required = TRUE)
    caption <- check_param(caption, 'char')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'photo' = httr::upload_file(photo),
                      'caption' = caption,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendPhoto', body = body)
    ## response handling
    invisible(r)
}

sendSticker <- function(sticker = NULL,
                        reply_to_message_id = NULL,
                        chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    sticker <- check_file(sticker, required = TRUE)
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'sticker' = httr::upload_file(sticker),
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendSticker', body = body)
    ## response handling
    invisible(r)
}

sendVideo <- function(video = NULL,
                      duration = NULL,
                      caption = NULL,
                      reply_to_message_id = NULL,
                      chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    video <- check_file(video, required = TRUE)
    duration <- check_param(duration, 'int')
    caption <- check_param(caption, 'char')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'video' = httr::upload_file(video),
                      'duration' = duration,
                      'caption' = caption,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendVideo', body = body)
    ## response handling
    invisible(r)
}

sendVoice <- function(voice = NULL,
                      duration = NULL,
                      reply_to_message_id = NULL,
                      chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    voice <- check_file(voice, required = TRUE)
    duration <- check_param(duration, 'int')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'voice' = httr::upload_file(voice),
                      'duration' = duration,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendVoice', body = body)
    ## response handling
    invisible(r)
}

setWebhook <- function() not_implemented()


## --------
## Exported
## --------

#' bot_token
#'
#' Obtain token from system variables (in \code{Renviron}) set
#' according to package naming conventions, that is
#' \code{R_TELEGRAM_X} where \code{X} is bot's name (first question
#' answered to the botfather).
#'
#' @param botname character of length 1 with the name of the bot
#' @examples \dontrun{
#' bot_token('RBot')
#' }
#' @export
bot_token <- function(botname = NULL){
    if (is.null(botname) || identical(botname, ''))
        stop("botname can't be missing.")
    varname <- paste0('R_TELEGRAM_BOT_', botname)
    value <- Sys.getenv(varname)
    if (!identical(value, ''))
        return(value)
    else
        stop(varname, ' environment variable is not available.')
}


#' TGBot
#'
#' Package main class (implementing the Telegram bot).
#' 
#' @docType class
#' @format An \code{\link{R6Class}} generator object.
#' @section API Methods:
#' \describe{
#'   \item{\code{getMe}}{tests your bot's auth token}
#'   \item{\code{sendMessage}}{Send text messages}
#'   \item{\code{forwardMessage}}{Forward messages of any kind}
#'   \item{\code{sendPhoto}}{Send image files.}
#'   \item{\code{sendAudio}}{Send \code{mp3} files}
#'   \item{\code{sendDocument}}{Send general files}
#'   \item{\code{sendSticker}}{Send \code{.webp} stickers}
#'   \item{\code{sendVideo}}{Send \code{mp4} videos}
#'   \item{\code{sendVoice}}{Send ogg files encoded with OPUS}
#'   \item{\code{sendLocation}}{Send point on the map}
#'   \item{\code{getUserProfilePhotos}}{Get a list of profile pictures for a user}
#'   \item{\code{getFile}}{Get basic info about a file and prepare it for downloading}
#' }
#' @references \href{http://core.telegram.org/bots}{Bots: An introduction for developers} and \href{http://core.telegram.org/bots/api}{Telegram Bot API}
#' @examples \dontrun{
#' bot <- TGBot$new(token = bot_token('RBot'))
#' }
#' @export
TGBot <- R6::R6Class("TGBot",
                     public = list(
                         ## class utils
                         initialize = initialize,
                         set_token = set_token,
                         set_default_chat_id = set_default_chat_id,
                         print = tgprint,
                         ## TG api
                         forwardMessage       = forwardMessage,
                         getFile              = getFile,
                         getMe                = getMe,
                         getUpdates           = getUpdates,
                         getUserProfilePhotos = getUserProfilePhotos,
                         sendAudio            = sendAudio,
                         sendChatAction       = sendChatAction,
                         sendDocument         = sendDocument,
                         sendLocation         = sendLocation,
                         sendMessage          = sendMessage,
                         sendPhoto            = sendPhoto,
                         sendSticker          = sendSticker,
                         sendVideo            = sendVideo,
                         sendVoice            = sendVoice,
                         setWebhook           = setWebhook
                     ),
                     private = list(
                         token = NULL,
                         default_chat_id = NULL,
                         bot_first_name = NULL,
                         bot_username = NULL,
                         request = request,
                         check_chat_id = check_chat_id
                         )
                     )


