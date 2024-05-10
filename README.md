# telegram

This package is a simple R wrapper around the
[Telegram](https://telegram.org/) [Bot
API](https://core.telegram.org/bots/api).

It allows to send messages (text, Markdown, images, files) from R to
your smartphone.

More infos on telegram's bot api can be found
[here](https://core.telegram.org/bots) and
[here](https://core.telegram.org/bots/api).

## How to install the package?
For the stable version:
```r
install.packages('telegram')
```
For the development one:
```r
devtools::install_github('lbraglia/telegram')
```


## First time setup

First you have to talk to the
[botfather](https://telegram.me/botfather) to create a new bot; answer
few questions regarding bot's name and you're ready to go.

After you've done, the botfather returns a token (which has to be kept
secret) that lets you handle your bot; we need this token when
creating the bot object on the R side. Following [Hadley's API
guidelines](https://github.com/r-lib/httr/blob/master/vignettes/api-packages.Rmd#appendix-api-key-best-practices)
it's unsafe to type the token just in the R script. It's better to use
enviroment variables set in `.Renviron` file.

So let's say you have named your bot `RBot` (it's the first question
you've answered to the botfather); then put the following line with
your token in your `.Renviron`:
```bash
R_TELEGRAM_BOT_RBot=123123:asdasdasd
```
If you follow the suggested `R_TELEGRAM_BOT_` prefix convention you'll be able
to use the `bot_token` function (otherwise you'll have to get
these variable from `Sys.getenv`).

After you've finished these steps **restart R** in order to have
working environment variables.


## How to connect R with Telegram

Now you should be able to obtain a connection to your bot 
with these commands:
```r
library(telegram)

## Create the bot object
bot <- TGBot$new(token = bot_token('RBot'))

## Now check bot connection it should print some of your bot's data
bot$getMe()

## Now, on the phone, find and say something to your bot to start a chat
## (and obtain a chat id).
## ...

## Here, check what you have inserted
bot$getUpdates()

## You're interested in the message.chat.id variable: in order to set a
## default chat_id for the following commands (to ease typing)
bot$set_default_chat_id(123456789)
```

After a bit using the package, you'll probably want to set the
`chat_id` to your user id (or more generally, have something like an
addressbook to store users' ids). If you put this in your `.Renviron`:
```bash
R_TELEGRAM_USER_me=123456789
```
you'll be able to use the `user_id` function, eg like this:
```r
bot$set_default_chat_id(user_id('me'))
```
Specularly if you need to interact frequently with a group, you may want 
to add this to your `.Renviron` (group chat id are negative integers):
```bash
R_TELEGRAM_GROUP_fav_group=-123456789
```
you'll be able to use the `group_id` function, eg like this:
```r
bot$set_default_chat_id(group_id('fav_group'))
```

## How to connect using a proxy
Proxy parameters are expected to be a named list (names as parameters
passed to `httr::use_proxy`:

```r

## On initialization speci
prx <- list('url' = '123.45.6.78',
            'port' = 8080,
            'username' = 'user',
            'password' = 'password')
bot <- TGBot$new(token = bot_token('RBot'), proxy = prx)

##  .. or later (but before requests) ...
bot <- TGBot$new(token = bot_token('RBot'))
bot$set_proxy(proxy = prx)

## if you want to save default proxy values in .Renviron using the following
## schema
##
## R_TELEGRAM_PROXY_default_url=123.45.6.78
## R_TELEGRAM_PROXY_default_port=8080
## R_TELEGRAM_PROXY_default_username=user
## R_TELEGRAM_PROXY_default_password=password
## R_TELEGRAM_PROXY_default_auth=basic
##
## you can use the proxy utility function
##

proxy('default')

## which should return
## 
## $auth
## [1] "basic"
## 
## $password
## [1] "password"
## 
## $port
## [1] "8080"
## 
## $url
## [1] "123.45.6.78"
## 
## $username
## [1] "user"
##
##
## therefore, for a handy one-liner:

bot <- TGBot$new(token = bot_token('RBot'), proxy = proxy('default'))
```

## Examples of methods currently implemented
Once you've followed the previous section, run the following commands
and look at your phone.

```r
## ------------------
## Send some messages
## ------------------
bot$sendMessage('This is plain text')

## Markdown support (version 2 via parse_mode = 'markdownv2')
md <- "
*bold* _italic_ [r-project](https://r-project.org) 
try `x <- rnorm(100)` at the console ...
you can have
    ``` 
    x <- runif(100)
    mean(x)
    ```
too
"
bot$sendMessage(md, parse_mode = 'markdown')
## HTML support (eg)
html_message <- "
<b>bold</b>, <i>italic</i>, <u>underline</u>,
<s>strikethrough</s>,
<a href='https://www.example.com/'>inline URL</a>
<a href='tg://user?id=123456789'>inline mention of a user</a>
<code>inline fixed-width code</code>
<pre>pre-formatted fixed-width code block</pre>
"
bot$sendMessage(html_message, parse_mode = 'html')

## -------------------
## Send an image/photo
## -------------------
png('test.png')
plot(rnorm(100))
dev.off()
bot$sendPhoto('test.png', caption = 'This is my awesome graph')

## ---------------------------------
## Send a document (can be any file)
## ---------------------------------
help(TGBot, help_type = 'pdf')
bot$sendDocument('TGBot.pdf')

## ---------------
## Send a location
## ---------------
bot$sendLocation(44.699, 10.6297)

## --------------
## Send a sticker
## --------------
bot$sendSticker(system.file('r_logo.webp', package = 'telegram'))

## ------------
## Send a video
## ------------
library(animation)
saveVideo({
    set.seed(1)
    nmax <- 10
    ani.options(interval = 0.4, nmax = nmax)
    x <- c()
    for (i in 1:nmax){
        x <- c(x, rnorm(1))
        plot(cumsum(x), lty = 2, xlim = c(1, nmax), ylim = c(-5, 5))
        abline(h = 0, col = 'red')
    }
}, video.name = 'animation.mp4')
bot$sendVideo('animation.mp4')

## --------------------
## Send mp3 audio files
## --------------------
bot$sendAudio(system.file('audio_test.mp3', package = 'telegram'),
              performer = 'espeak (https://espeak.sf.net)')

## ------------------------------------
## Send voice (opus encoded .ogg files)
## ------------------------------------
bot$sendVoice(system.file('voice_test.ogg', package = 'telegram'))

## -----------------------------------------------------------------
## Tell the user what's happening on the bot's side (for long tasks)
## -----------------------------------------------------------------
bot$sendChatAction('typing')
bot$sendChatAction('upload_photo')
bot$sendChatAction('record_video')
bot$sendChatAction('upload_video')
bot$sendChatAction('record_voice')
bot$sendChatAction('upload_voice')
bot$sendChatAction('upload_document')
bot$sendChatAction('find_location')
bot$sendChatAction('record_video_note')
bot$sendChatAction('upload_video_note')

## ----------------------------------------------------------
## Roll a dice (animation of a random number between 1 and 6)
## ----------------------------------------------------------
bot$sendDice()

## ------------
## Start a poll
## ------------
bot$sendPoll(question = 'What is your gender?',
             options = c('Female', 'Male'))
bot$sendPoll(question = "What was the color of Napoleon's horse?",
             options = c('black', 'yellow', 'white', 'green', 'pois'),
             is_anonymous = FALSE,
             type = 'quiz',
             correct_option_id = 2) ## it's 0 based so 2 is the third
                                    ## option (white)
bot$sendPoll(question = "Which genres of music do you listen to the most?",
             options = c('blues', 'rock', 'metal', 'rnb', 'jazz', 'pop'),
             is_anonymous = FALSE,
             allows_multiple_answers = TRUE)

## -----------------
## Forward a message
## -----------------
bot$forwardMessage(from_chat_id = 123456,
                   chat_id = 123456,
                   message_id = 35)

## ---------------------------
## Get info about user's photo
## ---------------------------
bot$getUserProfilePhotos(user_id('me')) # <- alternatively, message.from.id variable in getUpdates

## ------------------------------------
## Obtain files on the Telegram servers
## ------------------------------------
bot$getFile('asdasdasdqweqweqwe-UdYAAgI', # <- file_id from getUserProfilePhotos
            'me_small.png')

```
