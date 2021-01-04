# TidHub

Running several wikis via `Tiddlywiki` on `Node.js` from a command line can be a kind of pain in the ass. Especially if you run wikis in the background, use many terminals and have forgotten from which one you had run them or which ports you had assigned to them etc.

TidHub is a simple bash script that greatly simplifies management of wikis on your machine. Instead of remembering or finding paths, pids, ports it introduces concept of wiki *keys*. These Wiki keys are easy-to-write aliases to wikis on your computer which you define by yourself.

TidHub utilizes wiki keys list that is stored in a very simple config file. The config file template is created (if the user interactively agrees) by the program itself. You only have to edit this template.

## Functionality

TidHub

* **Starts** all|selected wikis in the background while automatically chooses tcp port to be listened.
* **Views** all|selected wikis in the default browser as http://localhost:port page.
* **Stops** all|selected wikis while automatically finds appropriate pid to be killed.
* **Prints** info status of all preconfigured wikis: key, path, pid, port in one well-arranged table.

TidHub has also quite detailed documentation about program usage and config file setup.

## Requirements

* Linux
[Tiddlywiki ver. >= 5.1.22 on Node.js](https://tiddlywiki.com/#Installing%20TiddlyWiki%20on%20Node.js) (obviously) and at the least one directory containing Tiddlywiki server-related components
* bash >= 4
* awk, sed, ss, grep, pgrep, xdg-open|x-wwwbrowser|sensible-browser

## Installation and running

1. Copy or move `tidhub.sh` into some directory on your PATH. I prefer either `~/bin/` or `~/.local/bin/`
2. cd into this directory and make `tidhub.sh` file permission executable (e.g. chmod u+x `tidhub.sh`)
3. Write into your terminal: `tidhub.sh` and you will be presented with program usage options or with an offer to create config file template.

## Timeline

* Project started on 2020-12-19.
* Version 1.0.0 released on 2021-01-03.

## Acknowledgment

Special thanks to

* Node.js Tiddlywiki developers - running several wikis on my desktop is easy as going to the hell (going to the heaven is rather difficult, isn't it?)
* Fossil VCS developers - my projects versions control is a fun childish play.

## Copyright notice

Copyright  2021 MarHaj at https://github.com/MarHaj/
under GNU General Public Licence version 3 or any later version, see <https://www.gnu.org/licenses/gpl-3.0.txt>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 or any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

