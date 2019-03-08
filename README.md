# Fluminus

[![Build Status](https://travis-ci.com/indocomsoft/fluminus.svg?branch=master)](https://travis-ci.com/indocomsoft/fluminus)
[![Coverage Status](https://coveralls.io/repos/github/indocomsoft/fluminus/badge.svg?branch=master)](https://coveralls.io/github/indocomsoft/fluminus?branch=master)

<sup><sub>F LumiNUS! IVLE ftw! Why fix what ain't broken?!</sub></sup>

If you are looking for the CLI tool, it has been refactored as a separate package: https://github.com/indocomsoft/fluminus_cli

Since IVLE will be deprecated next academic year (AY2019/2020), while LumiNUS has consistently pushed back its schedule to release an API, I have decided to reverse-engineer the API used by the Angular front-end of LumiNUS.

I try to keep to best coding practices and use as little dependencies as possible. Do let me know if you have any suggestions!

PR's are welcome.

![demo](demo.gif)

## Installation
### As a dependency

This package can be installed by adding `fluminus` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fluminus, "~> 0.2.3"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/fluminus](https://hexdocs.pm/fluminus).
