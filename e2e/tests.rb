require_relative "helper"

for test in Dir.glob(
  File.expand_path(
    File.join(__dir__, "tests", "**", "*.rb")
  )
) do
  load test
end
