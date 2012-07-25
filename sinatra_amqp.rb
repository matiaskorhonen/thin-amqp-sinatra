require "sinatra/base"
require "amqp"

class SinatraAMQP < Sinatra::Base
  register Sinatra::Async

  def amqp(&block)
    EventMachine.next_tick do
      if AMQP.connection
        p "Already connected"
        yield(AMQP.connection)
      else
        AMQP.connect(:host => "127.0.0.1") do |connection|
          AMQP.connection = connection
          p "Connected"
          yield(connection)
        end
      end
    end
  end

  aget "/" do
    content_type "text/plain"

    # Timeout if the request takes more than 5 seconds
    EventMachine.add_timer(5) { body { "Timeout" } }

    amqp do |connection|
      channel    = AMQP::Channel.new(connection)

      AMQP::Queue.new(channel, "", :exclusive => true, :auto_delete => true) do |replies_queue|
        puts "#{replies_queue.name} is ready to go."

        puts "[request] Sending a request..."
        channel.default_exchange.publish("get.time",
                                          :routing_key => "amqpgem.examples.services.time",
                                          :message_id  => SecureRandom.uuid,
                                          :reply_to    => replies_queue.name,
                                          :immediate   => true)

        replies_queue.subscribe do |metadata, payload|
          body {
            "Got a reply: #{payload}"
          }
        end
      end
    end
  end

end
