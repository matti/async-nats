require "async/nats"

client = Async::Nats::Client.new

client.start! do
  client.ping
end
