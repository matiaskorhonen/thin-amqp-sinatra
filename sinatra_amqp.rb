require "sinatra/base"
require "amqp"

class SinatraAMQP < Sinatra::Base

  def amqp(&block)
    AMQP.connect(:host => "127.0.0.1") do |connection|
      p "Connected"
      yield(connection)
    end
  end

  get "/" do
    content_type "text/plain"

    a = amqp do |connection|
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
          p "Got a reply: #{payload}"
        end
      end
    end

    "OK" # We'd want to return the payload and metadata here.
  end

end
