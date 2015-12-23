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

getMe <- function() {
    r <- private$request('getMe')
    status <- status_code(r)
    if (status == 200){
        c <- content(r)
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

getUpdates <- function(){
    r <- private$request('getUpdates')
    if (r$status == 200)
        return(r)
    else
        return(NULL)
}

## ----
## SEND
## ----

sendMessage <- function(text, chat_id){
    if (missing(chat_id))
        chat_id <- private$default_chat_id
    r <- private$request('sendMessage', 
                         body = list(
                             'chat_id' = chat_id,
                             'text' = as.character(text)))
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
                             'document' = upload_file(f)))
    invisible(r)
}



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
                         sendDocument = sendDocument                     
                     ),
                     private = list(
                         token = NA,
                         default_chat_id = NA,
                         request = request)
                     )



## bot <- TGBot$new(token = '163188543:AAHH8lwXaTCxnMsixmg5Y6aukCWbv-_jgME')
## bot$getMe()
## ## now find and say something to your bot on the phone
## b <- bot$getUpdates()
## bot$set_default_chat_id(162174388)

## bot$sendMessage('This is a test')
## png('test.png')
## plot(rnorm(100))
## dev.off()
## d <- bot$sendDocument('test.png')
