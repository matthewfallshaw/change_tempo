Change Tempo
============

[on OSX]

Increase the tempo of all tracks in the 'Podcasts' playlist in iTunes
(update state is stored in the mp3 'comments' tag, and already altered tracks
will not be re-fiddled, so running this multiple times shouldn't hurt)

## Dependencies:
```
$ brew install sox id3lib
$ sudo gem install activesupport rb-appscript id3lib-ruby
```
** (you can get Homebrew from http://mxcl.github.io/homebrew/, which'll make the ```brew```command work)


## Install:

Put this somewhere sensible (like ~/bin/change_tempo) and run it regularly, by, say:
```
  crontab -e
  15 3 * * * ~/bin/change_tempo.rb --speedup 20 --playlist new-podcasts > ~/log/change_tempo.log
```

