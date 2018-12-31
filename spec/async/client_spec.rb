RSpec.describe Async::Nats::Client do
  include_context Async::RSpec::Reactor

  let(:client) { Async::Nats::Client.new }
  after do
    client.stop!
  end

  describe "start!" do
    it do
      expect(client.start!).to be_an_instance_of Async::Nats::Client
    end
  end

  describe "with start!" do
    let(:client) {
      c = Async::Nats::Client.new
      c.start!
      c
    }

    describe "ping" do
      it do
        expect(client.ping).to be_an_instance_of Async::Nats::Client
      end
    end

    describe "pub" do
      it do
        expect(client.pub "void", nil).to be_an_instance_of Async::Nats::Client
      end
    end

    describe "sub" do
      it do
        done = Async::Notification.new
        got = nil
        client.sub "subject" do |msg|
          got = msg
          done.signal
        end
        client.pub "subject", "hello"
        done.wait

        expect( got ).to eq "hello"
      end

      it do
        done = Async::Notification.new
        got = nil
        client.sub "subject" do |msg|
          got = msg
          done.signal
        end
        client.pub "subject", "hello\r\nhallo"
        done.wait
        expect( got ).to eq "hello\r\nhallo"
      end

      it "calls .on!(:err) on invalid subscription" do
        got = nil
        done = Async::Notification.new

        client.on!(:err) do |msg|
          got = msg
          done.signal
        end
        client.sub "foo."

        done.wait
        expect(got).to eq "Invalid Subject"
      end

      describe "queue_groups" do
        it do
          a = []
          client.sub "queue_group", queue_group: "all" do
            a << true
          end

          b = []
          client.sub "queue_group", queue_group: "all" do
            b << true
          end

          10.times do
            client.pub "queue_group", true
          end

          loop do
            break if (a+b).size == 10
            Async::Task.current.sleep 0.1
          end
          expect(a.size).to be > 0
          expect(b.size).to be > 0

          expect(a.size).to be < 10
          expect(b.size).to be < 10

          expect((a+b).size).to eq 10
        end
      end
    end
  end
end
