require 'async/io'
require 'async/io/stream'
require 'async/io/protocol/line'
require 'async/queue'
require 'securerandom'
require 'json'

module Async
  module Nats
    class Client
      def initialize
        @endpoint = Async::IO::Endpoint.tcp('demo.nats.io', 4222)
        @write_queue = Async::Queue.new
        @notifications = {}

        @server_info = {}
        @connection = nil
        @read_task = nil
        @write_task = nil

        @pongs = Async::Queue.new

        @subscriptions = {}

        @events = {}
        @events[:err] = lambda do |msg|
          raise "ERR: #{msg}"
        end
        @events[:pong] = lambda do |now|
          "default pong handler"
        end

        @events[:ok] = lambda do |now|
          "default ok handler"
        end
      end

      def start!(&block)
        if !Async::Task.current? && block.nil?
          raise "Needs to be run inside of reactor or given a block"
        end

        ensure_connection_and_tasks_when_in_reactor_and_no_block = Async::Notification.new if Async::Task.current? && block.nil?

        Async::Reactor.run do
          @server_info, @connection, @stream, @line_protocol = __connect

          @read_task = __read_task
          @write_task = __write_task

          if block
            block.call
            stop!
          else
            ensure_connection_and_tasks_when_in_reactor_and_no_block.signal if ensure_connection_and_tasks_when_in_reactor_and_no_block
          end
        end
        ensure_connection_and_tasks_when_in_reactor_and_no_block.wait if ensure_connection_and_tasks_when_in_reactor_and_no_block
        self
      end

      def ping
        __call "PING", wait: true
        @pongs.dequeue
        self
      end

      def pub(subject, reply_to_or_msg, msg=nil)
        payload = if msg
          msg.to_s
        else
          reply_to_or_msg.to_s
        end

        __call "PUB #{subject} #{payload.size}\n#{payload}"
        self
      end

      def sub(subject, queue_group: nil, sid: nil, &block)
        sid = SecureRandom.uuid unless sid
        @subscriptions[sid] = block

        __call "SUB #{subject} #{sid}"

        sid
      end

      def unsub(sid, max_msgs=nil)
        unsub_msg = if max_msgs
          "UNSUB #{sid} #{max_msgs}"
        else
          "UNSUB #{sid}"
        end

        __call unsub_msg
        self
      end

      def stop!
        @write_task.stop
        @read_task.stop
        @connection.close
      end

      def on!(event, &block)
        @events[event] = [] if @events[event].is_a? Proc
        @events[event] << block
      end

      def flush!
        loop do
          break @write_queue.empty?
          Async::Task.current.sleep 0.1
        end
      end

      private

      def __call(msg, wait:false)
        if wait
          uuid = SecureRandom.uuid
          @notifications[uuid] = Async::Notification.new
          @write_queue.enqueue [uuid, msg]
          @notifications[uuid].wait
        else
          @write_queue.enqueue [nil, msg]
        end
      end

      def __connect
        connection = @endpoint.connect
        stream = Async::IO::Stream.new(connection)
        line_protocol = Async::IO::Protocol::Line.new(stream, "\r\n")

        info = line_protocol.read_line

        _, json, = info.split /^INFO (.*)/
        info = JSON.parse(json)

        [info, connection, stream, line_protocol]
      end

      def __read_task
        Async::Task.current.async do
          while data = @line_protocol.read_line
            p ["<-", data]
            case data
            when /^-ERR/
              _, msg, = data.split /^-ERR '([^']*)/
              __fire :err, msg
            when "PING"
              @line_protocol.write "PONG"
            when /^MSG/
              msg, subject, uuid, bytes_str = data.split(" ")
              bytes = bytes_str.to_i
              payload = @stream.read(bytes)
              @line_protocol.read_line

              Async::Task.current.async do
                @subscriptions[uuid].call payload
              end
            when "PONG"
              @pongs.enqueue Time.now
              __fire :pong, Time.now
            when "+OK"
              __fire :ok, Time.now
            else
              raise "unknown: #{data}"
            end
          end
        end
      end

      def __fire(event, *args)
        if @events[event].is_a? Proc
          @events[event].call *args
        else
          @events[event].each do |b|
            b.call *args
          end
        end
      end

      def __write_task
        Async::Task.current.async do
          while msg = @write_queue.dequeue do
            p ["->", msg]
            @line_protocol.write_lines msg.last
            @notifications[msg.first].signal if msg.first
          end
        end
      end
    end
  end
end
