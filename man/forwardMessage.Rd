% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TGBot.R
\name{forwardMessage}
\alias{forwardMessage}
\title{forwardMessage}
\usage{
forwardMessage(
  from_chat_id = NULL,
  message_id = NULL,
  disable_notification = NULL,
  chat_id = NULL
)
}
\arguments{
\item{from_chat_id}{Unique identifier for the chat where the
original message was sent (required)}

\item{message_id}{Unique message identifier (required)}

\item{disable_notification}{Sends the message silently. Users will
receive a notification with no sound}

\item{chat_id}{Unique identifier for the target chat or username of
the target channel (required)}
}
\description{
Forward messages of any kind
}
