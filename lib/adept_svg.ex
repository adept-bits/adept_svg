defmodule Adept.Svg do
  require Logger

  @moduledoc """
  Simple and fast in-line SVG library and renderer for web applications.

  SVG files are images that are formatted as very simple, and usually small, text
  files. It is faster, and recommended, that you directly include the svg data
  in-line with your web pages instead of asking the browser to make additional
  calls to servers before it can render your pages. This makes your pages load faster.

  `adept_svg` renders your svg files as quickly as possible. To do this, it reads
  the svg files at compile-time and provides runtime access through a term
  stored in your beamfile.

  If you use `nimble_publisher`, this should be a familiar concept.

  To use `adept_svg`, you create a module in your project that wraps it, providing
  a compile-time place to build the library and runtime access to it. It also happens
  to make your template svg rendering code very simple.

  You do __not__ need to store your svg files in the "assets/static" directory. Those files
  are copied into your application via a file based mechanism, whereas `adept_svg` compiles
  them in directly. I recommend simply using "assets/svg".

  Each `*.svg` file must contain a single valid `<svg></svg>` tag set with data as appropriate.
  Anything before the `<svg>` tag or after the `</svg>` is treated as comment and stripped
  from the text during compilation.

  ## Example wrapper module
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

  To use the library, you would `alias MyAppWeb.Svg` in a controller, live_view or
  your your main app module. This allows your template code to call Svg.render directly.

  ## Example use in a template
      <%= Svg.render( "heroicons/user", class: "h-5 w-5 inline" ) %>

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
  """


  defmodule Error do
    @moduledoc false
    defexception message: nil, svg: nil
  end


  #--------------------------------------------------------
  @doc """
  Compile a folder of `*.svg` files into a library you can render from.

  The folder and it's subfolders will be traversed and all valid `*.svg` files will
  be added to the library. Each svg will be added to the library with a key that is
  relative path of the svg file, minus the .svg part. For example, if you compile
  the folder "assets/svg" and it finds a file with the path "assets/svg/heroicons/calendar.svg",
  then the key for that svg is `"heroicons/calendar"` in the library.
  
  ## Usage

  The best way to use Adept.Svg is to create a new module in your project that wraps
  it, providing storage for the generated library term. This also allows you to customize
  naming, rendering or compiling as required.

  ## Example
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

  Note that @library is accessed through a function. The library could become large,
  so you want to wrap it with a function to ensure that it is only stored as a term
  in your beam file once.
  """
  @spec compile(map(), String.t()) :: map()
  def compile( %{} = library \\ %{}, svg_root  ) when is_bitstring(svg_root) do
    svg_root
    |> Kernel.<>( "/**/*.svg" )
    |> Path.wildcard()
    |> Enum.reduce( library, fn(path, acc) ->
      with {:ok, key, svg} <- read_svg( path, svg_root ),
      :ok <- unique_key( library, key, path ) do
        Map.put( acc, key, svg <> "</svg>" )
      else
        {:file_error, err, path} ->
          raise %Error{message: "SVG file #{inspect(path)} is invalid, err: #{err}", svg: path}
        {:duplicate, key, path} ->
          Logger.warn("SVG file: #{path} overwrites existing svg: #{key}")
      end
    end)
  end

  defp read_svg( path, root ) do
    with {:ok, svg} <- File.read( path ),
    true <- String.valid?(svg),
    [_,svg] <- String.split(svg, "<svg"),
    [svg,_] <- String.split(svg, "</svg>") do
      { 
        :ok,
        path # make the key
        |> String.trim(root)
        |> String.trim("/")
        |> String.trim_trailing(".svg"),
        svg
      }
    else
      err -> {:file_error, err, path}
    end
  end

  defp unique_key(library, key, path) do
    case Map.fetch( library, key ) do
      {:ok, _} -> {:duplicate, key, path}
      _ -> :ok
    end
  end

  #--------------------------------------------------------
  @doc """
  Renders an svg into a safe string that can be inserted directly into a Phoenix template.

  The named svg must be in the provided library, which should be build using the compile function.
  
  _Optional_: pass in a keyword list of attributes to insert into the svg tag. This can be
  used to add `class="something"` tag attributes, phoenix directives such as `phx-click`, or
  even alpine directives such as `@click="some action"`. Note that key names containing
  the underscore character `"_"` will be converted to the hyphen `"-"` character.


  You don't normally call `Adept.Svg.render()` directly, except in your wrapper module. Instead,
  you would `alias MyAppWeb.Svg` in a controller, live view or
  your your main app module. This allows your template code to call Svg.render directly, which
  is simple and looks nice.

  The following examples all use an aliased `MyAppWeb.Svg`, which wraps `Adept.Svg`.

  ## Example use in a template
      <%= Svg.render( "heroicons/menu" ) %>
      <%= Svg.render( "heroicons/user", class: "h-5 w-5 inline" ) %>

  ## Other examples
  Without attributes:
      Svg.render( "heroicons/menu" )
      {:safe, "<svg xmlns= ... </svg>"}

  With options:
      Svg.render( "heroicons/menu", class: "h-5 w-5" )
      {:safe, "<svg class=\"h-5 w-5\" xmlns= ... </svg>"}

      Svg.render( "heroicons/menu", phx_click: "action" )
      {:safe, "<svg phx-click=\"action\" xmlns= ... </svg>"}

      Svg.render( "heroicons/menu", "@click": "alpine_action" )
      {:safe, "<svg @click=\"alpine_action\" xmlns= ... </svg>"}
  """
  @spec render(map(), String.t(), list()) ::String.t()
  def render( %{} = library, key, attrs \\ [] ) do
    case Map.fetch( library, key ) do
      {:ok, svg} -> {:safe, "<svg" <> render_attrs(attrs) <> svg}
      _ -> raise %Error{message: "SVG #{inspect(key)} not found", svg: key}
    end
  end

  #--------------------------------------------------------
  # transform an opts list into a string of tag options
  defp render_attrs( attrs ), do: do_render_attrs( attrs, "" )
  defp do_render_attrs( [], acc ), do: acc
  defp do_render_attrs( [{key,value} | tail ], acc ) do
    key = to_string(key) |> String.replace("_", "-")
    do_render_attrs( tail, "#{acc} #{key}=#{inspect(value)}" )
  end
  
end
