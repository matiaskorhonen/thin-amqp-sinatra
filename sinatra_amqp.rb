require "sinatra/base"
require "amqp"

class SinatraAMQP < Sinatra::Base

  def amqp(&block)
    unless AMQP.connection
      AMQP.connection = AMQP.connect(:host => "127.0.0.1")
    end

    if AMQP.connection.connected?
      p "Connected"
      block.call
    else 
      p "Not Connected"
      AMQP.connection.register_connection_callback do
        raise "Error couldn't connect" unless AMQP.connection.connected?
        block.call
      end
    end
  end

  get "/" do
    amqp do
      MQ.queue("amqp.sinatra.thin.test", :durable => true).publish("test_message")
    end

    content_type "text/plain"
    "OK"
  end

end
