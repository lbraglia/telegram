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

make_methods_string <- function(meth, incipit){
    wrap_at <- 72
    meth_string <- paste0(incipit, '\n',  paste(meth, collapse = ", "))
    paste0(paste(strwrap(meth_string, width = wrap_at),
                 collapse = '\n'),
           '\n')
}

tgprint <- function(){
    obj <- objects(bot)

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
                'log'       = as.logical)
    if(is.null(param)){
        if (required) stop(char_name, " can't be missing.")
        else NULL
    }
    else coerce[[type]](param[1])
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
    ## request's body
    body <- list('chat_id' = chat_id,
                 'text' = as.character(text),
                 'parse_mode' = parse_mode,
                 'reply_to_message_id' = reply_to_message_id)
    body <- body[!unlist(lapply(body, is.null))]
    ## request
    r <- private$request('sendMessage', body = body)
    ## response handling
    invisible(r)
}


forwardMessage <- function(from_chat_id = NULL,
                           message_id = NULL,
                           chat_id = NULL)
{
    chat_id <- private$check_chat_id(chat_id = chat_id)
    if (is.null(from_chat_id) ||  is.null(message_id))
        stop("from_chat_id and message_id can't be missing")
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
                      chat_id = NULL)
{
    ## Param preprocessing
    chat_id <- private$check_chat_id(chat_id = chat_id)
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
                         chat_id = NULL)
{
    chat_id <- private$check_chat_id(chat_id = chat_id)
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
                         print = tgprint,
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
                         request = request,
                         check_chat_id = check_chat_id
                         )
                     )
