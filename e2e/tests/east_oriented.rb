require_relative "../helper"

client = Async::Nats::Client.new
pongs = []
client.on! :pong do
  pongs << true
end

test "east oriented" do
  group "reactor" do
    Async::Reactor.run do
      test "client.start!.ping.ping", binding

      wait_until_size pongs, 2
      client.stop!
    end
  end

  group "reactorless" do
    pongs = []
    client.start! do
      test "client.ping.ping", binding
      wait_until_size pongs, 2
    end
  end
end

