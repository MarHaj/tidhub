# Tidhub

Running several (Tiddly)wikis under Node.js from a command line is sometimes pain kind of the pain in the ass.

Tidhub is a bash script that

* keeps central list of user wikis in $HOME/.config/Tidhub/tidhubrc
* it enables the following operations with them:
	* listen to wiki (node.js command: tiddlywiki -- listen)
  * list running wikis
	* kill wikis gently (aka unlisten)

## Requirements

* tiddlywiki under Node.js (obviously)
* pgrep utility
* awk

## Timeline

* Project started on 2020-12-19.
