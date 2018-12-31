require "async/nats"

client = Async::Nats::Client.new

client.start! do
  done = Async::Notification.new
  client.sub "greetings" do |g|
    puts "Got: #{g}"
    done.signal
  end

  client.pub "greetings", "hello"
  done.wait
end
