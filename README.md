# TidHub

Running several wikis via Tiddlywiki on Node.js from a command line can be a kind of pain in the ass. Especially if you run wikis in the background, use many terminals and forgot from which one you have run them or forgot which ports you have assigned assigned to them etc.

TidHub is a simple bash script that greatly simplifies management of wikis on your machine. Instead of remembering or finding paths, pids, ports it introduces concept of wiki *keys*. Wiki keys are easy-to-write aliases to wikis on your computer which you define by yourself.

TidHub utilizes central user defined wiki key list in very simple config file, which is created as a template (if user interactively agrees) by the program itself. You have to only edit this template.

TidHub provides the following functionality:

* Starts all|selected wikis in the background (while automatically chooses tcp port to be listened).
* Views all|selected wikis in the default browser as http://localhost:port page.
* Views status of all preconfigured wikis: key (aka user shorcut), path, pid, port in one well-arranged table.
* Stops all|selected wikis (while automatically finds appropriate pid to be killed)

TidHub has also quite detailed documentation about program usage and config file setup.

## Requirements

* Linux
Tiddlywiki under Node.js (obviously)
* bash >= 4
* awk, sed, ss, grep, pgrep, xdg-open|x-wwwbrowser|sensible-browser

N.B.: **All preconfigured wikis has to reside under $HOME directory.**

## Timeline

* Project started on 2020-12-19.
* Version 1.00 released on 2021-01-02.

## Acknowledgement

Special thanks to

* Node.js Tiddlywiki developers - running several wikis on my desktop is easy as going to the hell (going to the heaven is rather difficult, isn't it?)
* Fossil VCS developers - my projects versions control is a fun childish play.

## Copyright notice

Copyright 2021 Martin Hájek <marhaj at gmx.com>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>
