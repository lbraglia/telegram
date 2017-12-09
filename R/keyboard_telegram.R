
KBtoJSON <- function(TGKeyboard = NULL){
  if(is.null(TGKeyboard)) NULL
  else{
    if(!inherits(TGKeyboard, "TGKeyboard")) stop("Incorrect Keyboard type.")
    jsonlite::toJSON(TGKeyboard, auto_unbox = T, force = T)
  }
}

#' KeyboardButton
#'
#' This object represents one button of the reply keyboard. Optional
#' fields are mutually exclusive.
#' 
#' \strong{Note:} \code{request_contact} and \code{request_location}
#' options will only work in Telegram versions released after 9 April,
#' 2016. Older clients will ignore them.
#' 
#' @param text Text of the button (Required). If none of the optional
#'     fields are used, it will be sent as a message when the button
#'     is pressed
#' @param request_contact If \code{TRUE}, the user's phone number will be
#'     sent as a contact when the button is pressed. Available in
#'     private chats only
#' @param request_location If \code{TRUE}, the user's current location
#'     will be sent when the button is pressed. Available in private
#'     chats only
#' @export

#' @export
KeyboardButton <- function(
  text = NULL,
  request_contact = NULL,
  request_location = NULL)
{
  ## params
  text <- check_param(text, 'char', required = TRUE)
  request_contact <- check_param(request_contact, 'log')
  request_location <- check_param(request_location, 'log')
  ## build object
  KeyboardButton <- list(text = text,
                         request_contact = request_contact,
                         request_location = request_location)
  KeyboardButton <- KeyboardButton[!unlist(lapply(KeyboardButton, is.null))]
  class(KeyboardButton) <- "KeyboardButton"
  ## return object
  return(KeyboardButton)
}

#' ReplyKeyboardMarkup
#'
#' This object represents a \href{https://core.telegram.org/bots#keyboards}{custom keyboard}
#' with reply options.
#' 
#' @param keyboard List of button rows, each represented by an list of
#'     \code{\link{KeyboardButton}} objects
#' @param resize_keyboard Requests clients to resize the keyboard vertically
#'     for optimal fit. Defaults to If \code{FALSE}, in which case the
#'     customkeyboard is always of the same height as the app's standard
#'     keyboard.
#' @param one_time_keyboard Requests clients to hide the keyboard as soon
#'     as it's been used. The keyboard will still be available, but clients
#'     will automatically display the usual letter-keyboard in the chat –
#'     the user can press a special button in the input field to see the
#'     custom keyboard again. Defaults to \code{FALSE}
#' @param selective Use this parameter if you want to show the keyboard
#'     to specific users only. 
#' @export

#' @export
ReplyKeyboardMarkup <- function(
  keyboard = NULL,
  resize_keyboard = NULL,
  one_time_keyboard = NULL,
  selective = NULL)
{
  ## params
  keyboard <- check_param(keyboard, 'list', required = TRUE)
  resize_keyboard <- check_param(resize_keyboard, 'log')
  one_time_keyboard <- check_param(one_time_keyboard, 'log')
  selective <- check_param(selective, 'log')
  ## check dimensions and class
  if(!(length(keyboard) %in% 1:2) |
     !all(unlist(lapply(keyboard, is.list))) |
     !all(unlist(lapply(keyboard, function(x){lapply(x, function(x){inherits(x, "KeyboardButton")})})))) {
    stop("keyboard parameter must be a list of button rows, each represented by a list of KeyboardButton objects")
  }
  ## build object
  ReplyKeyboardMarkup <- list(keyboard = keyboard,
                              resize_keyboard = resize_keyboard,
                              one_time_keyboard = one_time_keyboard,
                              selective = selective)
  ReplyKeyboardMarkup <- ReplyKeyboardMarkup[!unlist(lapply(ReplyKeyboardMarkup, is.null))]
  class(ReplyKeyboardMarkup) <- c("ReplyKeyboardMarkup", "TGKeyboard")
  ## return object
  return(ReplyKeyboardMarkup)
}

#' InlineKeyboardButton
#'
#' This object represents one button of an inline keyboard. You
#' \strong{must} use exactly one of the optional fields.
#' 
#' \strong{Note:} After the user presses a callback button,
#' Telegram clients will display a progress bar until you call
#' \code{\link{answerCallbackQuery}}. It is, therefore, necessary to
#' react by calling \code{\link{answerCallbackQuery}} even if no notification
#' to the user is needed (e.g., without specifying any of the
#' optional parameters).
#' 
#' @param text Label text on the button
#' @param url HTTP url to be opened when button is pressed
#' @param request_location Data to be sent in a
#'     \href{https://core.telegram.org/bots/api#callbackquery}{callback query}
#'     to the bot when button is pressed, 1-64 bytes
#' @param switch_inline_query If set, pressing the button will prompt the
#'     user to select one of their chats, open that chat and insert the
#'     bot‘s username and the specified inline query in the input field.
#'     Can be empty, in which case just the bot’s username will be inserted.
#' @param switch_inline_query_current_chat If set, pressing the button will
#'     insert the bot‘s username and the specified inline query in the current
#'     chat's input field. Can be empty, in which case only the bot’s username
#'     will be inserted.
#' @export

#' @export
InlineKeyboardButton <- function(
  text = NULL,
  url = NULL,
  callback_data = NULL,
  switch_inline_query = NULL,
  switch_inline_query_current_chat = NULL)
{
  ## params
  text <- check_param(text, 'char', required = TRUE)
  url <- check_param(url, 'char')
  callback_data <- check_param(callback_data, 'char')
  switch_inline_query <- check_param(switch_inline_query, 'char')
  switch_inline_query_current_chat <- check_param(switch_inline_query_current_chat, 'char')
  ## check that 1 and only 1 optional parameter is not NULL
  if (sum(sapply(list(url,
                      callback_data,
                      switch_inline_query,
                      switch_inline_query_current_chat),
                 function(x)!is.null(x))) != 1) stop("You must use exactly one of the optional fields.")
  ## build object
  InlineKeyboardButton <- list(text = text,
                               url = url,
                               callback_data = callback_data,
                               switch_inline_query = switch_inline_query,
                               switch_inline_query_current_chat = switch_inline_query_current_chat)
  InlineKeyboardButton <- InlineKeyboardButton[!unlist(lapply(InlineKeyboardButton, is.null))]
  class(InlineKeyboardButton) <- "InlineKeyboardButton"
  ## return object
  return(InlineKeyboardButton)
}

#' InlineKeyboardMarkup
#'
#' This object represents an \href{https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating}{inline keyboard}
#' that appears right next to the message it belongs to.
#' 
#' \strong{Note:} After the user presses a callback button,
#' Telegram clients will display a progress bar until you call
#' \code{\link{answerCallbackQuery}}. It is, therefore, necessary to
#' react by calling \code{\link{answerCallbackQuery}} even if no notification
#' to the user is needed (e.g., without specifying any of the
#' optional parameters).
#' 
#' @param inline_keyboard List of button rows, each represented by a list of
#'     \code{\link{InlineKeyboardButton}} objects
#' @export

#' @export
InlineKeyboardMarkup <- function(
  inline_keyboard = NULL)
{
  ## params
  inline_keyboard <- check_param(inline_keyboard, 'list', required = TRUE)
  ## check dimensions and class
  if(!(length(inline_keyboard) %in% 1:2) |
     !all(unlist(lapply(inline_keyboard, is.list))) |
     !all(unlist(lapply(inline_keyboard, function(x){lapply(x, function(x){inherits(x, "InlineKeyboardButton")})})))) {
    stop("keyboard parameter must be a list of button rows, each represented by a list of InlineKeyboardButton objects")
  }
  ## build object
  InlineKeyboardMarkup <- list(inline_keyboard = inline_keyboard)
  InlineKeyboardMarkup <- InlineKeyboardMarkup[!unlist(lapply(InlineKeyboardMarkup, is.null))]
  class(InlineKeyboardMarkup) <- c("InlineKeyboardMarkup", "TGKeyboard")
  ## return object
  return(InlineKeyboardMarkup)
}
