telegram [![Build Status](https://travis-ci.org/lbraglia/telegram.svg)](https://travis-ci.org/lbraglia/telegram)
========

This package is an R wrapper around the Telegram Bot API.

## How to connect R with Telegram?

```r
library(telegram)

## Talk to the botfather and create a new bot following the steps
## ...
## After you've done, put the returned token in the following command
## to handle the bot
bot <- TGBot$new(token = '123132132:asdasdasdasdasdasdasd')

## Now check bot connection it should print some of your bot's data
bot$getMe()

## Now find and say something to your bot on the phone to start a chat
## (and obtain a chat id).
## ...
## Here, check what you have inserted
bot$getUpdates()

## You're interested in the chat_id variable: in order to set a
## default chat_id for the following commands (to ease typing)
bot$set_default_chat_id(123456789)
```

## Example of methods currently implemented

```r
## Send some messages..
bot$sendMessage('This is a test')
md1 <- "*bold* _italic_ [r-project](http://r-project.org) "
md2 <- " try `x <- rnorm(100)` at the console ..."
md3 <- "
you can have
```
x <- runif(100)
mean(x)
```
too
"
bot$sendMessage(md1, parse_mode = 'markdown')
bot$sendMessage(md2, parse_mode = 'markdown')
bot$sendMessage(md3, parse_mode = 'markdown')

## Send a image/photo
png('test.png')
plot(rnorm(100))
dev.off()
bot$sendPhoto('test.png', caption = 'This is my awesome graph')

## Send a document (can be any file)
bot$sendDocument('final_analysis.pdf')

## Forward a message
bot$forwardMessage(from_chat_id = 162174388,
                   chat_id = 162174388,
                   message_id = 35)
```