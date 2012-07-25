#!/usr/bin/env ruby

require "rubygems"
require "eventmachine"

class RequestHandler < EventMachine::Connection
  attr_reader :args

  def initialize(args)
    @args = args
  end

  def post_init
    if @args[0] == "--addUser"

    else
      send_data ENV["APOLLO_USER"] + "#" + @args.join(" ")
    end
  end

  def receive_data(data)
    puts data
  end
end

def print_usage
  puts 'Usage:'
  puts "--addUser <user name>:<password>"
  puts "--createRepo <repository name>"
end

def preprocess_args(args)

  if args.length == 1 && args[0] == "--help"
    print_usage
    return 0
  end

  if args.length != 2
    print_usage
    return 0
  end

  if args[0] != "--addUser" && args[0] != "--createRepo"
    print_usage
    return 0
  end

  if args[0] != "--addUser"
    if ENV['APOLLO_USER'].nil?
      puts "Error: please run --addUser first"
      return 0
    end

    apollo_user = ENV['APOLLO_USER'].split(":")
    if apollo_user.length != 2
      puts "Error: please run --addUser to add a valid user"
      return 0
    end
  end

  if args[0] == "--addUser"
    if args[1].split(":").length != 2
      puts "Error: please add a valid user and password pair <user name>:<password>"
    else
      ENV["APOLLO_USER"] = args[1]
      system({"APOLLO_USER" => args[1]}, "export $APOLLO_USER=$args[1]")
    end
    return 0
  end
  1
end

def main(args)
  if preprocess_args(args) == 0
    return 1
  end

  EventMachine.run {
    EventMachine.connect '127.0.0.1', 8081, RequestHandler, args
  }
end

exit(main(ARGV))
