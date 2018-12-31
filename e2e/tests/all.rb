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
