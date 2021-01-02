# TidHub

Running several wikis via Tiddlywiki on Node.js from a command line can be kind of pain in the ass. Especially if you run wikis in the background, use many terminals and forgot from which one you have run them.

TidHub is a simple bash script that greatly simplifies control of wikis on your machine. Instead of remembering or finding paths, pids, ports it introduces concept of wiki *keys*. Wiki keys are easy-to-write aliases to wikis on your computer which you define by yourself.

TidHub utilizes central user defined wikis list in ~/.config/Tidhub/tidhubrc, which is created, if user interactivelly agrees, by the program itself. You have to only edit this tempalte.

TidHub

* Provides the following functionality:
	* Starts all|selected wikis in the background (while automatically chooses tcp port to be listened).
	* Views all|selected wikis in the default browser as http://localhost:port page.
	* Views status of all preconfigured wikis: key (aka user shorcut), path, pid, port in one well-arranged table.
	* Stops all|selected wikis (while automatically finds appropriate pid to be killed)

TidHub also has quite detailed documentation about program usage and tidhubrc setup.

## Requirements

* Linux
Tiddlywiki under Node.js (obviously)
* bash >= 4
* awk, sed, ss, grep, pgrep, xdg-open|x-wwwbrowser|sensible-browser

N.B.: **All preconfigured wikis has to reside under $HOME directory.**

## Timeline

* Project started on 2020-12-19.
* All of the functionalities done and tested 2021-01-02.
* Version 1.00 released on 2021-01-02.

## Acknowledgement

Special thanks to

* Node.js Tiddlywiki developers - running several wikis on my desktop is easy as going to the hell (going to the heaven is rather difficult, isn't it?)
* Fossil VCS developers - my projects versions control is a fun childish play.
