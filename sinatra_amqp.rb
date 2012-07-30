require "sinatra/base"
require "amqp"
require "securerandom"

class SinatraAMQP < Sinatra::Base
  register Sinatra::Async

  def amqp(&block)
    EventMachine.next_tick do
      if AMQP.connection && AMQP.connection.connected?
        p "Already connected"
        yield(AMQP.connection)
      else
        AMQP.connect(:host => "127.0.0.1", :on_tcp_connection_failure => proc { puts "TCP Failed" }) do |connection|
          AMQP.connection = connection
          AMQP.connection.on_tcp_connection_loss do |connection, settings|
            # reconnect in 10 seconds, without enforcement
            connection.reconnect(false, 10)
          end
          p "Connected"
          yield(connection)
        end
      end
    end
  end

  aget "/" do
    content_type "text/plain"

    # Timeout if the request takes more than 5 seconds
    timer = EventMachine::Timer.new(5) { body { "Timeout" } }

    amqp do |connection|
      channel    = AMQP::Channel.new(connection)

      AMQP::Queue.new(channel, "", :exclusive => true, :auto_delete => true) do |replies_queue|
        puts "#{replies_queue.name} is ready to go."

        puts "[request] Sending a request..."
        channel.default_exchange.publish("get.time",
                                          :routing_key => "amqpgem.examples.services.time",
                                          :message_id  => SecureRandom.hex(32),
                                          :reply_to    => replies_queue.name,
                                          :immediate   => true)

        replies_queue.subscribe do |metadata, payload|
          body {
            timer.cancel
            "Got a reply: #{payload}"
          }
        end
      end
    end
  end

end
