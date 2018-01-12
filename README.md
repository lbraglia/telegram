# telegram

[![Version](https://img.shields.io/badge/version-0.6.2--dev-green.svg)]()
[![Travis CI Status](https://travis-ci.org/ebeneditos/telegram.svg?branch=master)](https://travis-ci.org/ebeneditos/telegram)

This updates the [`telegram`](https://github.com/lbraglia/telegram) package by:

- **Adding `timeout` argument**  to the `getUpdates` function, so to use Long Polling.

- **Keyboard displaying**, which includes parameter `reply_markup` from `sendMessage` function with its objects:
    - ReplyKeyboardMarkup
    - InlineKeyboardMarkup
    - ReplyKeyboardRemove
    - ForceReply
    
- **Adding `answerCallbackQuery` method**.

- **Adding `sendChatAction` method**.

This version is being reviewed so to update the stable version, for now you can download its developers one with:

```r
devtools::install_github('ebeneditos/telegram')
```

Make sure you have the `devtools` package updated.
