require "async/nats"

a = []
b = []

Async::Reactor.run do
  consumer_a = Async::Nats::Client.new
  consumer_a.start!
  consumer_a.sub "queue_group", queue_group: "all" do |msg|
    a << msg
  end

  consumer_b = Async::Nats::Client.new
  consumer_b.start!
  consumer_b.sub "queue_group", queue_group: "all" do |msg|
    b << msg
  end

  producer = Async::Nats::Client.new
  producer.start!
  10.times do
    producer.pub "queue_group", 1
  end

  loop do
    break if (a+b).size == 10
    Async::Task.current.sleep 0.1
  end

  consumer_a.stop!
  consumer_b.stop!
  producer.stop!
end
