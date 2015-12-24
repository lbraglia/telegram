telegram [![Build Status](https://travis-ci.org/lbraglia/telegram.svg)](https://travis-ci.org/lbraglia/telegram)
========

This package is an R wrapper around the
[Telegram](http://telegram.org/) [Bot
API](http://core.telegram.org/bots/api).

It allows to send messages (text, Markdown, images, files) from R to
your smartphone.

More infos on telegram's bot api can be found
[here](http://core.telegram.org/bots) and
[here](http://core.telegram.org/bots/api).

## How to install the package?
```r
devtools::install_github('lbraglia/telegram')
```
The package imports some function from `R6` and `httr`, which are needed.

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

## You're interested in the message.chat.id variable: in order to set a
## default chat_id for the following commands (to ease typing)
bot$set_default_chat_id(123456789)
```

## Examples of methods currently implemented
Once you've followed the previous section, run the following commands
and look at your phone.

```r
## Send some messages..
bot$sendMessage('This is text')
## Markdown support for messages
md1 <- "*bold* _italic_ [r-project](http://r-project.org) "
md2 <- " try `x <- rnorm(100)` at the console ..."
## below left spaces just for github displaying (not needed in the .R src)
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