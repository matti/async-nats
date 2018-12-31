require "async/nats"

client = Async::Nats::Client.new
Async::Reactor.run do
  client.start!
  done = Async::Notification.new
  client.on! :pong do
    puts "PONG"
    done.signal
  end

  client.ping
  done.wait
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
