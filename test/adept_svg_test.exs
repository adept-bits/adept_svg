defmodule Adept.SvgTest do
  use ExUnit.Case
  doctest Adept.Svg

  import ExUnit.CaptureLog
  require Logger

  # build the svg library at compile time
  @svg_library Adept.Svg.compile("test/svgs")

  def library(), do: @svg_library

  # --------------------------------------------------------
  # compile

  test "compile traversed the tree, built nested paths, and stripped the .svg from the name" do
    assert Map.get(library(), "x")
    assert Map.get(library(), "nested/list")
    assert Map.get(library(), "more/cube")
  end

  test "compile can be piped into multiple folders" do
    library =
      Adept.Svg.compile("test/svgs/more")
      |> Adept.Svg.compile("test/svgs/nested")

    refute Map.get(library, "x")
    assert Map.get(library, "list")
    assert Map.get(library, "cube")
  end

  test "compile logs a warning when overwriting an existing svg file" do
    log =
      capture_log(fn ->
        Adept.Svg.compile("test/svgs/more")
        |> Adept.Svg.compile("test/svgs/more")
      end)

    assert log =~ "[warn]  SVG file:"
    assert log =~ "overwrites existing svg: cube"
  end

  test "compile raises an error when reading an invalid svg file" do
    assert_raise Adept.Svg.Error, fn ->
      Adept.Svg.compile("test/svg_invalid")
    end
  end

  # --------------------------------------------------------
  # render

  test "render retrieves the svg as a safe string" do
    {:safe, svg} = Adept.Svg.render(library(), "x")
    assert String.starts_with?(svg, "<svg xmlns=")
  end

  test "render preserves the tailing </svg>" do
    {:safe, svg} = Adept.Svg.render(library(), "x")
    assert String.ends_with?(svg, "</svg>")
  end

  test "render inserts optional attributes" do
    {:safe, svg} = Adept.Svg.render(library(), "x", class: "test_class", "@click": "action")
    assert String.starts_with?(svg, "<svg class=\"test_class\" @click=\"action\" xmlns=")
  end

  test "render converts attrs with the _ character into - " do
    {:safe, svg} = Adept.Svg.render(library(), "x", test_attr: "some_data")
    assert String.starts_with?(svg, "<svg test-attr=\"some_data\" xmlns=")
  end

  test "render raises an error if the svg is not in the library" do
    assert_raise Adept.Svg.Error, fn ->
      Adept.Svg.render(library(), "missing")
    end
  end
end
