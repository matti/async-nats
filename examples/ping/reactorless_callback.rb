require "async/nats"

client = Async::Nats::Client.new

client.start! do
  done = Async::Notification.new
  client.on! :pong do
    puts "PONG"
    done.signal
  end

  client.ping
  done.wait
end

