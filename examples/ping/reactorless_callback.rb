require "async/nats"

client = Async::Nats::Client.new

client.start! do
  client.on! :pong do
    puts "PONG"
  end

  client.ping
end

