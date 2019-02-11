# Fluminus

[![Build Status](https://travis-ci.com/indocomsoft/fluminus.svg?branch=master)](https://travis-ci.com/indocomsoft/fluminus)
[![Coverage Status](https://coveralls.io/repos/github/indocomsoft/fluminus/badge.svg?branch=master)](https://coveralls.io/github/indocomsoft/fluminus?branch=master)

<sup><sub>F LumiNUS! IVLE ftw! Why fix what ain't broken?!</sub></sup>

Since IVLE will be deprecated next academic year (AY2019/2020), while LumiNUS has consistently pushed back its schedule to release an API, I have decided to reverse-engineer the API used by the Angular front-end of LumiNUS. Currently, my goal is to be able to automatically download files a la [ivle-sync](https://github.com/goweiwen/ivle-sync), which is achieved as of v0.1.0!

I try to keep to best coding practices and use as little dependencies as possible. Do let me know if you have any suggestions!

PR's are welcome.

![demo](demo.gif)

## CLI Usage
The most important one, to download your files:

```bash
mkdir /tmp/fluminus
mix fluminus --download-to=/tmp/fluminus
```

This will download files of all your modules locally to the directory you speficied. To download all files again next time, simply do:

```bash
mix fluminus --download-to=/tmp/fluminus
```

## Installation
### CLI
1. Install elixir+erlang for your platform
2. Clone this repo
3. Get the dependencies:
```bash
mix deps.get
```
4. Fluminus CLI is available as a mix task:
```bash
mix fluminus
```

Note that the first time running the mix task might be a bit slow because
the code has to be compiled first.

### As a dependency

This package can be installed by adding `fluminus` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fluminus, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/fluminus](https://hexdocs.pm/fluminus).

## Roadmap
- [ ] Write tests, mock with ExVCR
