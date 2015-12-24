## ------
## UTILS
## ------

self <- 'shut up R CMD CHECK'
private <- 'shut up R CMD CHECK'

initialize <- function(token) {
    self$set_token(token)
}

set_token <- function(token){
    if (!missing(token))
        private$token <- token
}

set_default_chat_id <- function(chat_id){
    if (!missing(chat_id)) private$default_chat_id <- as.character(chat_id)
}

request <- function(method, body){
    if (missing(body))
        body <- NULL
    api_url <- sprintf('https://api.telegram.org/bot%s/%s',
                       private$token,
                       method)
    httr::POST(url = api_url, body = body)
}


## ------
## TG API
## ------

getMe <- function() {
    r <- private$request('getMe')
    status <- httr::status_code(r)
    if (status == 200){
        c <- httr::content(r)
        bot_first_name <- c$result$first_name
        bot_username <- c$result$username
        cat(sprintf('Bot name:\t%s\nBot username:\t%s\n',
                    bot_first_name, bot_username))
        return(r)
    } else {
        warning(sprintf('Status code: %d', status))
        return(NULL)
    }
}


sendMessage <- function(text, chat_id){
    if (missing(chat_id)) chat_id <- private$default_chat_id
    r <- private$request('sendMessage', 
                         body = list(
                             'chat_id' = chat_id,
                             'text' = as.character(text)))
    invisible(r)
}


forwardMessage <- function(from_chat_id, message_id, chat_id){
    if (missing(chat_id)) chat_id <- private$default_chat_id
    if (missing(from_chat_id) ||  missing(message_id))
        stop("forwardMessage: from_chat_id and message_id can't be missing")
    
    r <- private$request('forwardMessage', 
                         body = list(
                             'chat_id' = chat_id,
                             'from_chat_id' = chat_id,
                             'message_id' = as.character(message_id)))
    invisible(r)
}

sendPhoto <- function(photo, caption, reply_to_message_id,
                      reply_markup, chat_id){
    if (missing(chat_id)) chat_id <- private$default_chat_id
    if (missing(photo)) stop("sendPhoto: photo can't be missing")
    if (missing(caption)) caption <- NULL
    if (missing(reply_to_message_id)) reply_to_message_id <- NULL
    if (missing(reply_markup)) reply_markup <- NULL

   
    r <- private$request('forwardMessage', 
                         body = list(
                             'chat_id' = chat_id,
                             'photo' = httr::upload_file(photo)## ,
                             ## 'caption' = caption,
                             ## 'reply_to_message_id' = reply_to_message_id,
                             ## 'reply_markup' = reply_markup
                         ))
    invisible(r)

}


sendDocument <- function(f, chat_id){
    if (missing(chat_id))
        chat_id <- private$default_chat_id
    if (!file.exists(f))
        stop(f, 'is not a valid path (missing file?)')
    r <- private$request('sendDocument',
                         body = list(
                             'chat_id' = chat_id,
                             'document' = httr::upload_file(f)))
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


## ----------
## Main Class
## ----------

#' TGBot
#'
#' @export
TGBot <- R6::R6Class("TGBot",
                     public = list(
                         ## class utils
                         initialize = initialize,
                         set_token = set_token,
                         set_default_chat_id = set_default_chat_id,
                         ## TG api
                         getMe = getMe,
                         getUpdates = getUpdates,
                         sendMessage = sendMessage,
                         forwardMessage = forwardMessage,
                         sendPhoto = sendPhoto,
                         sendDocument = sendDocument                     
                     ),
                     private = list(
                         token = NA,
                         default_chat_id = NA,
                         request = request)
                     )
