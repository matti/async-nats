require "async/nats"

client = Async::Nats::Client.new

client.start! do |task|
  puts "about to do blocking sub"
  client.sub "waits", wait: true do
    puts "got"
  end
  puts "blocking sub done"

  puts "about to do blocking pub"
  client.pub "waits", true, wait: true
  puts "blocking pub done"

  puts "about to do async pub"
  client.pub "waits", true
  puts "async pub done"
  task.sleep 1
end
