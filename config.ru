require "rubygems"
require "bundler"

$stdout.sync = true

Bundler.require

require "./sinatra_amqp"
run SinatraAMQP