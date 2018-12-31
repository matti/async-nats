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

record "pub/sub", <<~EOF
  got = Async::Notification.new

  client.sub "subjekt" do |msg|
    got.signal
  end
  client.pub "subjekt", "hello"

  got.wait
EOF

record "sub+pub+pub", <<~EOF
  invocations = []
  done = Async::Notification.new
  client.sub "subjekt" do |msg|
    invocations << msg
    done.signal if invocations.size == 2
  end
  client.pub "subjekt", "hello"
  client.pub "subjekt", "hello"

  done.wait
EOF

record "ping", <<~EOF
  client.ping
EOF

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

client = Async::Nats::Client.new

test "needs reactor or block" do
  client.start!
rescue RuntimeError => ex
  raise ex unless ex.message == "Needs to be run inside of reactor or given a block"
end

test "client start! with block" do
  client.start! {}
end

test "client start/stop in reactor" do
  Async::Reactor.run do |task|
    client.start!
    client.stop!
  end
end

test "client start with block in reactor" do
  Async::Reactor.run do |task|
    client.start! {}
  end
end

tests = ["ping", "pub/sub", "sub+pub+pub"]

group "reactor start stop" do
  Async::Reactor.run do |task|
    client.start!
    play tests, binding
    client.stop!
  end
end

group "reactor block" do
  Async::Reactor.run do |task|
    client.start! do
      play tests, binding
    end
  end
end

group "reactorless" do
  client.start! do
    play tests, binding
  end
end

Async::Reactor.run do |task|
  client.start!
  client.ping

  notification_when_enough_messages = Async::Notification.new
  received_messages = []
  sid = client.sub "subs" do |msg|
    p ["GOT", msg]
    received_messages << msg
    notification_when_enough_messages.signal if received_messages.size == 2
  end

  client.pub "subs", "hello"
  client.pub "subs", "hello"

  client.unsub sid
  client.pub "subs", "hello"

  notification_when_enough_messages.wait

  notification_when_invalid_sub_subject = Async::Notification.new
  client.on! :err do |e|
    puts "ERRRRRROOR: #{e}"
    notification_when_invalid_sub_subject.signal
  end

  begin
    client.sub "invalid.", {}
  rescue RuntimeError => ex
  end

  notification_when_invalid_sub_subject.wait

  client.flush!
  client.stop!
end

test "east oriented" do
  pongs = []
  client.on!(:pong) do |now|
    pongs << now
  end

  group "reactor" do
    Async::Reactor.run do
      test "client.start!.ping.ping.stop!", binding
    end
    assert pongs.size, 2
  end

  group "reactorless" do
    pongs = []
    client.start! do
      test "client.ping.ping", binding
    end

    assert pongs.size, 2
  end
end
