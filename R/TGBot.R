## ------
## UTILS
## ------

self    <- 'shut up R CMD CHECK'
private <- 'shut up R CMD CHECK'
not_implemented <- function() stop('Currently not implemented')

initialize <- function(token, proxy) {
    self$set_token(token)
    self$set_proxy(proxy)
}

set_token <- function(token){
    if (!missing(token))
        private$token <- token
}

set_proxy <- function(proxy){
    if (!missing(proxy)){
        if (is.list(proxy)){
            private$proxy_url      <- as.character(proxy$url)
            private$proxy_port     <- as.integer(proxy$port)
            private$proxy_username <- as.character(proxy$username)
            private$proxy_password <- as.character(proxy$password)
            private$proxy_auth     <-
                if ("auth" %in% names(proxy)) as.character(proxy$auth)
                else 'basic'
            private$proxy_set      <- TRUE
        } else {
            private$proxy_set <- FALSE
        }
    } else {
        private$proxy_set <- FALSE
    }
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

request <- function(method = NULL, body = NULL){
    if (is.null(method)) stop("method can't be null")
    api_url <- sprintf('https://api.telegram.org/bot%s/%s',
                       private$token,
                       method)
    private$lr_method <- method
    private$lr_body <- body
    private$lr_response <- r <-
        if (private$proxy_set) {
            ## use proxy
            httr::POST(url = api_url,
                       body = body,
                       httr::use_proxy(
                                 url = private$proxy_url,
                                 port = private$proxy_port,
                                 username = private$proxy_username,
                                 password = private$proxy_password,
                                 auth = private$proxy_auth))
        } else {
            ## without proxy
            httr::POST(url = api_url, body = body)
        }
    httr::warn_for_status(r)
    r
}

last_request <- function(){
    list('method'   = private$lr_method,
         'body'     = private$lr_body,
         'response' = private$lr_response)
}

## pretty printer for methods
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
                     'sendPoll',
                     "sendLocation",
                     "sendChatAction",
                     "getUserProfilePhotos",
                     "getUpdates",
                     ## "setWebhook",
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

## check for user insertion for a method
## - param is the insertion
## - type is data type
## - required is if the parameter is required for the method
## - if scalar is TRUE take only the first element (of the object, eg
##   the vector)
check_param <- function(param, type, required = FALSE, scalar = TRUE){
    char_name <- deparse(substitute(char))
    coerce <- c('char'      = as.character,
                'int'       = as.integer,
                'log'       = as.logical,
                'float'     = as.numeric)
    if(is.null(param)){
        if (required) stop(char_name, " can't be missing.")
        else NULL
    } else {
        ## scalar by default (but if set to false leave a vector of
        ## parameters (eg used in sendPoll for answers)
        rval <- coerce[[type]](param)
        if (scalar) rval <- rval[1]
        rval
    }
}

check_file <- function(path, required = FALSE){
    if (file.exists(path))
        path
    else {
        if (required) stop(path, 'is not a valid path')
        else NULL
    }
}

parsed_content <- function(x){
    tx <- httr::content(x, as = 'text', encoding = 'UTF-8')
    rval <- jsonlite::fromJSON(tx)$result
    rval
}


## ------
## TG API
## ------

#' forwardMessage
#'
#' Forward messages of any kind
#' 
#' @param from_chat_id Unique identifier for the chat where the
#'     original message was sent (required)
#' @param message_id Unique message identifier (required)
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
forwardMessage <- function(from_chat_id = NULL,
                           message_id = NULL,
                           disable_notification = NULL,
                           chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    from_chat_id <- check_param(from_chat_id, 'char', required = TRUE)
    message_id <- check_param(message_id, 'char', required = TRUE)
    disable_notification <- check_param(disable_notification, 'log')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'from_chat_id' = from_chat_id,
                      'disable_notification' = disable_notification,
                      'message_id' = message_id)
    ## request
    r <- private$request('forwardMessage', body = body)
    ## response handling
    invisible(r)
}

#' getFile
#'
#' Get info about a file and download it
#'
#' @param file_id File identifier (required)
#' @param destfile Destination path; if specified the file will be
#'     downloaded
getFile <- function(file_id, destfile = NULL) {
    file_id <- check_param(file_id, 'char', required = TRUE)
    ## request body
    body <- make_body('file_id' = file_id)
    ## request
    r <- private$request('getFile', body = body)
    ## response handling
    if (r$status == 200){
        path <- parsed_content(r)$file_path
        dl_url <- sprintf('https://api.telegram.org/file/bot%s/%s',
                          private$token,
                          path)
        if (!is.null(destfile))
            curl::curl_download(dl_url, destfile = destfile)
        invisible(dl_url)
    } else
        invisible(NULL)
}

#' getMe
#'
#' Test your bot's auth token
getMe <- function()
{
    r <- private$request('getMe')
    if (r$status == 200){
        pc <- parsed_content(r)
        private$bot_first_name <- pc$first_name
        private$bot_username <- pc$username
        cat(sprintf('Bot name:\t%s\nBot username:\t%s\n',
                    private$bot_first_name,
                    private$bot_username))
    } 
    invisible(r)
}

#' getUpdates
#'
#' Receive incoming updates
#' 
#' @param offset Identifier of the first update to be returned.
#' @param limit Limits the number of updates to be retrieved. Values
#'     between 1-100 are accepted. Defaults to 100
getUpdates <- function(offset = NULL,
                       limit = NULL)
{
    ## params
    offset <- check_param(offset, 'int')
    limit <- check_param(limit, 'int')
    ## request body
    body <- make_body('offset' = offset,
                      'limit' = limit)
    r <- private$request('getUpdates', body = body)
    if (r$status == 200){
        rval <- parsed_content(r)
        return(rval)
    }
    else
        invisible(NULL)
}

#' getUserProfilePhotos
#'
#' Get a list of profile pictures for a user
#' 
#' @param user_id Unique identifier of the target user (required)
#' @param offset Sequential number of the first photo to be
#'     returned. By default, all photos are returned
#' @param limit Limits the number of photos to be retrieved. Values
#'     between 1-100 are accepted. Defaults to 100
getUserProfilePhotos <- function(user_id = NULL,
                                 offset = NULL,
                                 limit = NULL)
{
    ## params
    user_id <- check_param(user_id, 'int', required = TRUE)
    offset <- check_param(offset, 'int')
    limit <- check_param(limit, 'int')
    ## request body
    body <- make_body('user_id' = user_id,
                      'offset' = offset,
                      'limit' = limit)
    ## request
    r <- private$request('getUserProfilePhotos', body = body)
    ## response handling
    if (r$status == 200){
        file_id <- parsed_content(r)$photos
        rval <- do.call(rbind, file_id)
        return(rval)
    } else
        invisible(NULL)
}



#' sendAudio
#'
#' Send \code{mp3} files
#' 
#' @param audio path to audio file to send (required)
#' @param duration duration of the audio in seconds
#' @param performer performer
#' @param title track name
#' @param caption audio caption
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param reply_to_message_id If the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendAudio <- function(audio = NULL,
                      caption = NULL,
                      duration = NULL,
                      performer = NULL,
                      title = NULL,
                      disable_notification = NULL,
                      reply_to_message_id = NULL,
                      chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    caption <- check_param(caption, 'char')
    audio <- check_file(audio, required = TRUE)
    duration <- check_param(duration, 'int')
    performer <- check_param(performer, 'char')
    title <- check_param(title, 'char')
    disable_notification <- check_param(disable_notification, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'audio' = httr::upload_file(audio),
                      'caption' = caption,
                      'duration' = duration,
                      'performer' = performer,
                      'title' = title,
                      'disable_notification' = disable_notification,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendAudio', body = body)
    ## response handling
    invisible(r)
}

#' sendChatAction
#'
#' Tell the user that something is happening on the bot's side
#' @param action type of action to broadcast. Choose one, depending on
#'     what the user is about to receive: "typing" for text messages,
#'     "upload_photo" for photos, "record_video" or "upload_video" for
#'     videos, "record_voice" or "upload_voice" for voice notes,
#'     "upload_document" for general files, "find_location" for
#'     location data, "record_video_note" or "upload_video_note" for
#'     video notes.
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendChatAction <- function(action = NULL,
                           chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    action <- check_param(action, 'char')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'action' = action)
    ## request
    r <- private$request('sendChatAction', body = body)
    ## response handling
    invisible(r)
}

#' sendDocument
#'
#' Send general files
#' 
#' @param document path to the file to send (required)
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param reply_to_message_id if the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendDocument <- function(document = NULL,
                         disable_notification = NULL,
                         reply_to_message_id = NULL,
                         chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    document <- check_file(document, required = TRUE)
    disable_notification <- check_param(disable_notification, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'document' = httr::upload_file(document),
                      'disable_notification' = disable_notification,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendDocument', body = body)
    ## response handling
    invisible(r)
}

#' sendLocation
#'
#' Send point on the map
#' 
#' @param latitude Latitude of location (required)
#' @param longitude Longitude of location (required)
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param reply_to_message_id If the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendLocation <- function(latitude = NULL,
                         longitude = NULL,
                         disable_notification = NULL,
                         reply_to_message_id = NULL,
                         chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    latitude <- check_param(latitude, 'float', required = TRUE)
    longitude <- check_param(longitude, 'float', required = TRUE)
    disable_notification <- check_param(disable_notification, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'latitude' = latitude,
                      'longitude' = longitude,
                      'disable_notification' = disable_notification,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendLocation', body = body)
    ## response handling
    invisible(r)
}

#' sendMessage
#'
#' Send text messages
#' 
#' @param text Text of the message to be sent (required)
#' @param parse_mode send 'Markdown' if you want Telegram apps to show
#'     bold, italic and inline URLs in your bot's message
#' @param disable_web_page_preview Disables link previews for links in
#'     this message
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param reply_to_message_id If the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendMessage <- function(text = NULL,
                        parse_mode = NULL,
                        disable_web_page_preview = NULL,
                        disable_notification = NULL,
                        reply_to_message_id = NULL,
                        chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    text <- check_param(text, 'char', required = TRUE)
    parse_mode <- check_param(parse_mode, 'char')
    disable_web_page_preview <- check_param(disable_web_page_preview, 'log')
    disable_notification <- check_param(disable_notification, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'text' = as.character(text),
                      'parse_mode' = parse_mode,
                      'disable_web_page_preview' = disable_web_page_preview,
                      'disable_notification' = disable_notification,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendMessage', body = body)
    ## response handling
    invisible(r)
}

#' sendPhoto
#'
#' Send image files
#' 
#' @param photo photo to send (required)
#' @param caption photo caption
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param reply_to_message_id If the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendPhoto <- function(photo = NULL,
                      caption = NULL,
                      disable_notification = NULL,
                      reply_to_message_id = NULL,
                      chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    photo <- check_file(photo, required = TRUE)
    caption <- check_param(caption, 'char')
    disable_notification <- check_param(disable_notification, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'photo' = httr::upload_file(photo),
                      'caption' = caption,
                      'disable_notification' = disable_notification,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendPhoto', body = body)
    ## response handling
    invisible(r)
}

#' sendSticker
#'
#' Send \code{.webp} stickers
#' 
#' @param sticker sticker to send (required)
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param reply_to_message_id If the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendSticker <- function(sticker = NULL,
                        disable_notification = NULL,
                        reply_to_message_id = NULL,
                        chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    sticker <- check_file(sticker, required = TRUE)
    disable_notification <- check_param(disable_notification, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'sticker' = httr::upload_file(sticker),
                      'disable_notification' = disable_notification,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendSticker', body = body)
    ## response handling
    invisible(r)
}

#' sendVideo
#'
#' Send \code{mp4} videos
#' 
#' @param video Video to send (required)
#' @param duration Duration of sent video in seconds
#' @param caption Video caption
#' @param reply_to_message_id If the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
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

#' sendVoice
#'
#' Send \code{.ogg} files encoded with OPUS
#' 
#' @param voice Audio file to send (required)
#' @param duration Duration of sent audio in seconds
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param reply_to_message_id If the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendVoice <- function(voice = NULL,
                      duration = NULL,
                      disable_notification = NULL,
                      reply_to_message_id = NULL,
                      chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    voice <- check_file(voice, required = TRUE)
    duration <- check_param(duration, 'int')
    disable_notification <- check_param(disable_notification, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'voice' = httr::upload_file(voice),
                      'duration' = duration,
                      'disable_notification' = disable_notification,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendVoice', body = body)
    ## response handling
    invisible(r)
}

#' sendDice
#'
#' Use this method to send a dice, which will have a random value from
#' 1 to 6.
#'
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
sendDice <- function(disable_notification = NULL,
                     chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    disable_notification <- check_param(disable_notification, 'log')
    ## request body
    body <- make_body(
        'chat_id' = chat_id,
        'disable_notification' = disable_notification)
    ## request
    r <- private$request('sendDice', body = body)
    ## response handling
    invisible(r)
}

#' sendPoll
#'
#' Use this method to send a native poll.
#' 
#' @param question Poll question, 1-255 characters
#' @param options vector of possible answers: 2-10 strings 1-100
#'     characters each
#' @param is_anonymous if TRUE (default) the poll needs to be
#'     anonymous
#' @param type poll type, 'quiz' or 'regular', defaults to 'regular'
#' @param allows_multiple_answers if TRUE the poll allows multiple
#'     answers (default to FALSE and ignored for polls in quiz mode)
#' @param correct_option_id 0-based identifier of the correct answer
#'     option, required for polls in quiz mode (eg 0 set the first
#'     answer as correct)
#' @param is_closed if TRUE the poll needs to be immediately
#'     closed. This can be useful for poll preview. (default to FALSE)
#' @param disable_notification Sends the message silently. Users will
#'     receive a notification with no sound
#' @param reply_to_message_id If the message is a reply, ID of the
#'     original message
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
#' 
sendPoll <- function(question = NULL,
                     options = NULL,
                     is_anonymous = TRUE,
                     type = c('regular', 'quiz'),
                     allows_multiple_answers = FALSE,
                     correct_option_id = NULL,
                     is_closed = FALSE,
                     disable_notification = NULL,
                     reply_to_message_id = NULL,
                     chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    question <- check_param(question, 'char')
    options <- check_param(options, 'char', scalar = FALSE)
    is_anonymous <- check_param(is_anonymous, 'log')
    type <- match.arg(type)
    allows_multiple_answers <- check_param(allows_multiple_answers, 'log')
    ## correct options is required only for quiz polls
    correct_option_id <- check_param(
        correct_option_id, 'int', required = type %in% 'quiz')
    is_closed <- check_param(is_closed, 'log')
    disable_notification <- check_param(disable_notification, 'log')
    reply_to_message_id <- check_param(reply_to_message_id, 'int')
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'question' = question,
                      'options' = jsonlite::toJSON(options),
                      'is_anonymous' = is_anonymous,
                      'type' = type,
                      'allows_multiple_answers' = allows_multiple_answers,
                      'correct_option_id' = correct_option_id,
                      'disable_notification' = disable_notification,
                      'is_closed' = is_closed,
                      'reply_to_message_id' = reply_to_message_id)
    ## request
    r <- private$request('sendPoll', body = body)
    ## response handling
    invisible(r)
}


#' stopPoll
#'
#' Use this method to stop a poll which was sent by the bot.
#' 
#' @param message_id Identifier of the original message with the poll
#' @param chat_id Unique identifier for the target chat or username of
#'     the target channel (required)
stopPoll <- function(message_id = NULL,
                     chat_id = NULL)
{
    ## params
    chat_id <- private$check_chat_id(chat_id = chat_id)
    ## message_id <- check_param(message_id, 'int', required = TRUE)
    
    ## request body
    body <- make_body('chat_id' = chat_id,
                      'message_id' = message_id)
    ## request
    r <- private$request('stopPoll', body = body)
    ## response handling
    invisible(r)
}


## setWebhook <- function() not_implemented()


#' TGBot
#'
#' Package main class (implementing the Telegram bot).
#' 
#' @docType class
#' @format An \code{\link[R6]{R6Class}} generator object.
#' @section API Methods: \describe{
#'     \item{\code{\link{forwardMessage}}}{forward messages of any
#'     kind} \item{\code{\link{getFile}}}{get info about a file and
#'     download it} \item{\code{\link{getMe}}}{test your bot's auth
#'     token} \item{\code{\link{getUpdates}}}{receive incoming
#'     updates} \item{\code{\link{getUserProfilePhotos}}}{get a list
#'     of profile pictures for a user}
#'     \item{\code{\link{sendAudio}}}{send \code{mp3} files}
#'     \item{\code{\link{sendDocument}}}{send general files}
#'     \item{\code{\link{sendLocation}}}{send point on the map}
#'     \item{\code{\link{sendMessage}}}{send text messages}
#'     \item{\code{\link{sendPhoto}}}{send image files}
#'     \item{\code{\link{sendSticker}}}{send \code{.webp} stickers}
#'     \item{\code{\link{sendVideo}}}{send \code{mp4} videos}
#'     \item{\code{\link{sendVoice}}}{send ogg files encoded with
#'     OPUS} 
#'     \item{\code{\link{sendPoll}}}{send a telegram poll}
#'     \item{\code{\link{stopPoll}}}{stop a telegram poll and obtain results}
#' }
#' @references \href{http://core.telegram.org/bots}{Bots: An
#'     introduction for developers} and
#'     \href{http://core.telegram.org/bots/api}{Telegram Bot API}
#' @examples \dontrun{
#' 
#' ## Without proxy
#' bot <- TGBot$new(token = bot_token('RBot'))
#' 
#' ## With a proxy ...
#' prx <- list('url' = '123.45.6.78',
#'             'port' = 8080,
#'             'username' = 'user',
#'             'password' = 'password')
#' bot <- TGBot$new(token = bot_token('RBot'), proxy = prx)
#' ##  .. or 
#' bot <- TGBot$new(token = bot_token('RBot'))
#' bot$set_proxy(proxy = prx)
#' }
#' @export
TGBot <- R6::R6Class("TGBot",
                     public = list(
                         ## ---------------------
                         ## methods - class utils
                         ## ---------------------
                         initialize = initialize,
                         set_token = set_token,
                         set_proxy = set_proxy,
                         set_default_chat_id = set_default_chat_id,
                         print = tgprint,

                         ## This is for development/debug only, comment on release!
                         req = request,
                         last_request = last_request,

                         ## ---------------------
                         ## methods - TG api
                         ## ---------------------
                         
                         ## later or never
                         ## --------------
                         ## sendAnimation 
                         ## sendMediaGroup
                         ## sendVideoNote
                         ## **LiveLocation
                         ## sendChatAction
                         ## sendVenue
                         ## sendContact
                         ## **Chat*
                         ## answerCallbackQuery
                         ## setMyCommands
                         ## other **Sticker** stuff
                         
                         forwardMessage       = forwardMessage,
                         getFile              = getFile,
                         getMe                = getMe,
                         getUpdates           = getUpdates,
                         getUserProfilePhotos = getUserProfilePhotos,
                         sendAudio            = sendAudio,
                         sendChatAction       = sendChatAction,
                         sendDice             = sendDice,
                         sendDocument         = sendDocument,
                         sendLocation         = sendLocation,
                         sendMessage          = sendMessage,
                         sendPhoto            = sendPhoto,
                         sendPoll             = sendPoll,
                         sendSticker          = sendSticker,
                         sendVideo            = sendVideo,
                         sendVoice            = sendVoice,
                         ## setWebhook           = setWebhook,
                         stopPoll             = stopPoll
                         
                     ),
                     private = list(
                         ## ---------------------
                         ## members
                         ## ---------------------
                         token = NULL,
                         default_chat_id = NULL,
                         bot_first_name = NULL,
                         bot_username = NULL,
                         ## proxy data
                         proxy_set      = NULL,
                         proxy_url      = NULL,
                         proxy_port     = NULL,
                         proxy_username = NULL,
                         proxy_password = NULL,
                         proxy_auth     = NULL,
                         ## last request (LR) infos
                         lr_method = NULL,    ## method
                         lr_body = NULL,      ## body
                         lr_response = NULL,  ## response
                         ## ---------------------
                         ## methods
                         ## ---------------------
                         request = request,   ## make the request
                         check_chat_id = check_chat_id
                         )
                     )
