require "async/nats"

client = Async::Nats::Client.new

client.start! do
  done = Async::Notification.new
  got = nil
  sid1 = client.sub "greetings" do |g|
    puts "sid1 got it"
    raise "I can only be called once" if got
    got = g
    done.signal
  end

  client.pub "greetings", "hello"
  done.wait

  client.unsub sid1

  done2 = Async::Notification.new
  sid2 = client.sub "greetings" do |g|
    puts "sid2 got it"
    done2.signal
  end

  client.pub "greetings", "hello"
  done2.wait
  client.stop!
end
