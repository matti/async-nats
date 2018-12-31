require "async/nats"

client = Async::Nats::Client.new
Async::Reactor.run do
  client.start!
  client.on! :pong do
    puts "PONG"
  end

  client.ping
  client.stop!
end

Async::Reactor.run do
  client.start! do
    client.on! :pong do
      puts "PONG"
    end

    client.ping
  end
end
