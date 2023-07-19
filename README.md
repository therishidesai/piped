# piped

A pipe multiplexer inspired by [plumber](https://en.m.wikipedia.org/wiki/Plumber_(program)).

## Features

Currently, piped is an m:n IPC mechanism that will send data from m publishers to all n subscribers.

## Usage

Run piped as a daemon (e.g use systemd or background process)

To publish messages use pubmsg which reads messages on stdin. For example :

``` sh
od < /dev/urandom | pubmsg
```

To subscribe to messages from all publishers use submsg which will output the messages on stdout:

``` sh
submsg
```

## TODO

- [ ] More bandwidth tests
- [ ] Make simpler
- [ ] Make faster
