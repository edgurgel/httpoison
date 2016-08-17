ExUnit.start

defmodule PathHelpers do
  def fixture_path do
    Path.expand("fixtures", __DIR__)
  end

  def fixture_path(file_path) do
    Path.join fixture_path(), file_path
  end
end
