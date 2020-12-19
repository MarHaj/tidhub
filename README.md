# Tidhub

Running several (Tiddly)wikis under Node.js from a command line is sometimes kind of pain in the ass. Especially if you use many terminals and forgot from which one you run them.

Tidhub is a simple bash script that

* keeps central list of user defined wikis in ~/.config/Tidhub/tidhubrc
* enables following operations with those preconfigured wikis:
	* run all|selected wikis (node.js command: tiddlywiki --listen)
  * make a list of all preconfigured wikis with R flag if running
	* stop all|selected wikis (kill gently)

## Requirements

* Tiddlywiki under Node.js (obviously)
* bash >= 4
* awk, pgrep, pkill utilities

## Timeline

* Project started on 2020-12-19.

## Acknowledgement

Special thanks to

* Node.js Tiddlywiki developers - running several wikis on my desktop is easy as going to the hell (going to the heaven is rather difficult, isn't it?)
* Fossil VCS developers - my projects versions control is fun childish play.
