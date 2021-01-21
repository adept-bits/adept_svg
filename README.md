# Adept.Svg

A tiny and fast library to compile and render inline SVGs for Phoenix templates and live views.

SVG files are images that are formatted as very simple, and usually small, text
files. It is faster, and recommended, that you directly include the svg data
in-line with your web pages instead of asking the browser to make additional
calls to servers before it can render your pages. This makes your pages load faster.

`adept_svg` renders your svg files as quickly as possible. To do this, it reads
the svg files at compile-time and provides runtime access through a term
stored in your beamfile.

If you use [`nimble_publisher`](https://github.com/dashbitco/nimble_publisher), this should be a familiar concept.

To use `adept_svg`, you create a module in your project that wraps it, providing
a compile-time place to build the library and runtime access to it. It also happens
to make your template svg rendering code very simple.

You do __not__ need to store your svg files in the "assets/static" directory. Those files
are copied into your application via a file based mechanism, whereas `adept_svg` compiles
them in directly. I recommend simply using "assets/svg".

Each `*.svg` file must contain a single valid `<svg></svg>` tag set with data as appropriate. Anything before the `<svg>` tag or after the `</svg>` is treated as comment and stripped from the text during compilation.


## Example wrapper module

```elixir
defmodule MyAppWeb.Svg do

  # Build the library at compile time
  @library Adept.Svg.compile( "assets/svg" )

  # Accesses the library at run time
  defp library(), do: @library

  # Render an svg from the library
  def render( key, opts \\ [] ) do
    Adept.Svg.render( library(), key, opts )
  end
end
```

To use the library, you would `alias MyAppWeb.Svg` in a controller, live_view or
your your main app module. This allows your template code to call Svg.render directly.

## Example uses in a template

```elixir
<%= Svg.render( "heroicons/menu" ) %>
<%= Svg.render( "heroicons/user", class: "h-5 w-5 inline" ) %>
<%= Svg.render( "heroicons/login", class: "h-5 w-5", phx_click: "action" )
<%= Svg.render( "heroicons/logout", "@click": "alpine_action" )
```

### Live reloading

If you are using Phoenix, you can enable live reloading by simply telling Phoenix to watch the svgs directory.
Open up "config/dev.exs", search for `live_reload:` and add this to the list of patterns:

```elixir
live_reload: [
  patterns: [
    ...,
    ~r"assets/svg/*/.*(svg)$"
  ]
]
```


## License

Copyright 2021 Boyd Multerer

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.