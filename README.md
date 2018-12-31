# async-nats

*WIP* only works against demo.nats.io

Usage without `Async::Reactor`

        client = Async::Nats::Client.new

        client.start! do
          client.ping
        end

Usage with `Async::Reactor`

        require "async/nats"

        client = Async::Nats::Client.new

        Async::Reactor.run do
          client.start!
          client.ping
          client.stop!
        end

Pub/Sub

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
