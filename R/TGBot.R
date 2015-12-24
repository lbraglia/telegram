## ------
## UTILS
## ------

self    <- 'shut up R CMD CHECK'
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

getMe <- function()
{
    r <- private$request('getMe')
    status <- httr::status_code(r)
    if (status == 200){
        c <- httr::content(r)
        bot_first_name <- c$result$first_name
        bot_username <- c$result$username
        cat(sprintf('Bot name:\t%s\nBot username:\t%s\n',
                    bot_first_name, bot_username))
    } 
    invisible(r)
}


sendMessage <- function(text,
                        parse_mode,
                        disable_web_page_preview,
                        reply_to_message_id,
                        chat_id)
{
    if (missing(chat_id)){
        if (is.null(private$default_chat_id))
            stop("sendPhoto: chat_id can't be missing")
        else chat_id <- private$default_chat_id
    }
    if (missing(text)) stop("sendMessage: text can't be missing")
    text <- as.character(text[1])
    parse_mode <- if(missing(parse_mode)) NULL
                  else as.character(parse_mode[1])
    disable_web_page_preview <-
        if(missing(disable_web_page_preview)) NULL
        else as.logical(disable_web_page_preview[1])
    reply_to_message_id <-
        if(missing(reply_to_message_id)) NULL
        else as.integer(reply_to_message_id[1])
    body <- list('chat_id' = chat_id,
                 'text' = as.character(text),
                 'parse_mode' = parse_mode,
                 'reply_to_message_id' = reply_to_message_id)
    body <- body[!unlist(lapply(body, is.null))]
    r <- private$request('sendMessage', body = body)
    invisible(r)
}


forwardMessage <- function(from_chat_id,
                           message_id,
                           chat_id)
{
    if (missing(chat_id)){
        if (is.null(private$default_chat_id))
            stop("sendPhoto: chat_id can't be missing")
        else chat_id <- private$default_chat_id
    }
    if (missing(from_chat_id) ||  missing(message_id))
        stop("forwardMessage: from_chat_id and message_id can't be missing")
    from_chat_id <- as.character(from_chat_id[1])
    message_id <- as.character(message_id[1])
    body <- list('chat_id' = chat_id,
                 'from_chat_id' = chat_id,
                 'message_id' = message_id)
    r <- private$request('forwardMessage', body = body)
    invisible(r)
}


sendPhoto <- function(photo,
                      caption,
                      reply_to_message_id,
                      reply_markup,
                      chat_id)
{
    ## Param preprocessing
    if (missing(chat_id)){
        if (is.null(private$default_chat_id))
            stop("sendPhoto: chat_id can't be missing")
        else chat_id <- private$default_chat_id
    }
    if (!file.exists(photo))
        stop('sendPhoto: ', photo, 'is not a valid path.')
    caption <-
        if(missing(caption)) NULL
        else as.character(caption[1])
    reply_to_message_id <-
        if(missing(reply_to_message_id)) NULL
        else as.integer(reply_to_message_id[1])
    body <- list('chat_id' = chat_id,
                 'photo' = httr::upload_file(photo),
                 'caption' = caption,
                 'reply_to_message_id' = reply_to_message_id)
    body <- body[!unlist(lapply(body, is.null))]
    r <- private$request('sendPhoto', body = body)
    invisible(r)
}


sendDocument <- function(document,
                         reply_to_message_id,
                         chat_id)
{
    if (missing(chat_id)){
        if (is.null(private$default_chat_id))
            stop("sendDocument: chat_id can't be missing")
        else chat_id <- private$default_chat_id
    }
    if (!file.exists(document))
        stop('sendDocument', document,
             'is not a valid path (missing file?)')
    reply_to_message_id <-
        if(missing(reply_to_message_id)) NULL
        else as.integer(reply_to_message_id[1])
    body <- list('chat_id' = chat_id,
                 'document' = httr::upload_file(document),
                 'reply_to_message_id' = reply_to_message_id)
    body <- body[!unlist(lapply(body, is.null))]
    r <- private$request('sendDocument', body = body)
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
#' @examples \dontrun{
#' ## Talk to the botfather and create a new bot following the steps
#' ## ...
#' ## After you've done, put the returned token in the following command
#' ## to handle the bot
#' bot <- TGBot$new(token = '123132132:asdasdasdasdasdasdasd')
#'
#' ## Now check bot connection it should print some of your bot's data
#' bot$getMe()
#'
#' ## Now find and say something to your bot on the phone to start a chat
#' ## (and obtain a chat id).
#' ## ...
#' ## Here, check what you have inserted
#' bot$getUpdates()
#'
#' ## You're interested in the message.chat.id variable: in order to set a
#' ## default chat_id for the following commands (to ease typing)
#' bot$set_default_chat_id(123456789)
#'
#' ## Send some messages..
#' bot$sendMessage('This is text')
#' ## Markdown support for messages
#' md1 <- "*bold* _italic_ [r-project](http://r-project.org) "
#' md2 <- " try `x <- rnorm(100)` at the console ..."
#' md3 <- "
#' you can have
#' ```
#' x <- runif(100)
#' mean(x)
#' ```
#' too
#' "
#' bot$sendMessage(md1, parse_mode = 'markdown')
#' bot$sendMessage(md2, parse_mode = 'markdown')
#' bot$sendMessage(md3, parse_mode = 'markdown')

#' ## Send a image/photo
#' png('test.png')
#' plot(rnorm(100))
#' dev.off()
#' bot$sendPhoto('test.png', caption = 'This is my awesome graph')

#' ## Send a document (can be any file)
#' bot$sendDocument('final_analysis.pdf')

#' ## Forward a message
#' bot$forwardMessage(from_chat_id = 162174388,
#'                    chat_id = 162174388,
#'                    message_id = 35)

#' }
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
                         token = NULL,
                         default_chat_id = NULL,
                         request = request)
                     )
