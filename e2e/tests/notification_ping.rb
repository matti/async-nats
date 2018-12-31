require_relative "../helper"
client = Async::Nats::Client.new

client.start! do
  done = Async::Notification.new
  client.on!(:pong) do
    done.signal
  end

  client.ping
  done.wait
end
