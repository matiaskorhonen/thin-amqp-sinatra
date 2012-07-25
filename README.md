# Sinatra, Thin, & AMQP Proof of Concept

Prerequisites: Ruby, Homebrew, Bundler

*OS X is presumed in these instructions*

**Install and start RabbitMQ**

    brew install rabbitmq
    rabbitmq-server

**Install the gem bundle and start the server**

    bundle install
    foreman start
    open http://localhost:5000

Navigate to <http://localhost:5000> and watch the logs.
