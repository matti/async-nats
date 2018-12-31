require "async/nats"

client = Async::Nats::Client.new

client.start! do |task|
  client.on!(:pong) do
    puts "got pong"
  end

  puts "about to do blocking ping"
  client.ping wait: true
  puts "blocking ping done"

  puts "about to do async ping"
  client.ping
  puts "async ping done"
  task.sleep 1
end
