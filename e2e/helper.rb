require_relative "../lib/async/nats"
require 'colorize'

def assert(what, expected)
  raise "#{what.inspect} != #{expected}" unless what == expected
end

def record(name, source)
  $__records ||= {}
  $__records[name] = source
end

def play(name_or_array, binding)
  names = case name_or_array
  when String
    [name_or_array]
  when Array
    name_or_array
  end

  for name in names do
    unless $__records[name]
      raise "no such record exists: #{name}"
    end

    puts "-- play:start #{name}".colorize(:light_blue)
    binding.eval $__records[name]
    puts "-- play:stop #{name}".colorize(:light_blue)
  end
end

def test(what, binding=nil, &block)
  puts "-- test:start #{what}".colorize(:light_blue)
  if block
    block.call
  elsif binding
    binding.eval what
  else
    raise "needs binding with eval or block"
  end
  puts "-- test:stop #{what}".colorize(:light_blue)
  puts ""
end

def group(which, &block)
  puts "## group:start #{which}".colorize(:light_green)
  block.call
  puts "## group:end #{which}".colorize(:light_green)
  puts ""
end

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

require_relative "misc/all.rb"
