require 'colorize'

for example in Dir.glob(
  File.expand_path(
    File.join(__dir__, "..", "examples", "**", "*.rb")
  )
  ) do

  puts "-- example:start #{example}".colorize(:light_green)
  load example
  puts "-- example:stop #{example}".colorize(:light_green)
  puts ""
end
