require "async/nats"

client = Async::Nats::Client.new

Async::Reactor.run do
  client.start!
  client.ping
  client.stop!
end

Async::Reactor.run do
  client.start! do
    client.ping
  end
end
