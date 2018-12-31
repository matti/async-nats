require "async/nats"

client = Async::Nats::Client.new

Async::Reactor.run do
  client.start!

  done = Async::Notification.new
  client.sub "greetings" do |g|
    puts "Got: #{g}"
    done.signal
  end

  client.pub "greetings", "hello"
  done.wait
  client.stop!
end
