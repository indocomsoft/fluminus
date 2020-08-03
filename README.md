# Fluminus

[![Build Status](https://travis-ci.com/indocomsoft/fluminus.svg?branch=master)](https://travis-ci.com/indocomsoft/fluminus)
[![Coverage Status](https://coveralls.io/repos/github/indocomsoft/fluminus/badge.svg?branch=master)](https://coveralls.io/github/indocomsoft/fluminus?branch=master)

<sup><sub>F LumiNUS! IVLE ftw! Why fix what ain't broken?!</sub></sup>

If you are looking for the CLI tool, it has been refactored as a separate package: https://github.com/indocomsoft/fluminus_cli

Since IVLE was deprecated on AY2019/2020, while LumiNUS had consistently pushed back its schedule to release an API, I have decided to reverse-engineer the API used by the Angular front-end of LumiNUS.

> Recall all the posts that complained about how slow LumiNUS is? That’s an example of the difference between code that works and well-designed code that works efficiently.
- A/P Ooi Wei Tsang, NUS School of Computing[^1]

[^1]: https://www.facebook.com/nuswhispers/posts/2555462971190815?comment_id=2556787264391719

As evident from the quote, LumiNUS is infamous for its slow speed (and in my opinion, ridiculous API). As such, for Fluminus, I try to keep to best coding practices and do things efficiently, such as HTTP connection pooling, ensuring that there is no O(n^2) algorithm, not creating requests for information that has previously been obtained, and only creating requests to the backend that are absolutely necessary (looking at you, LumiNUS Angular Frontend).

Do let me know if you have any suggestions!

PR's are welcome.

Note that this is created through reverse-engineering LumiNUS's Angular Frontend. The API might change at any time (although I doubt it since LumiNUS is using OpenID Connect)

## Features
- Authentication via ADFS (vafs.nus.edu.sg)
- Get name of student
- Get list of modules
  - Taking/Teaching
  - Only this semester's modules
- Get announcements
- Get listing of workbin files and download them
- Get listing of webcasts and download them
- Get listing of weekly lesson plans and their associated files, and download them
- Get listing of multimedia files and download them

## Installation
### As a dependency

This package can be installed by adding `fluminus` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fluminus, "~> 2.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/fluminus](https://hexdocs.pm/fluminus).
