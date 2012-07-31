#!/usr/bin/env ruby

require "rubygems"
require "eventmachine"
require 'yaml'

def write_config(name, value)
  data = {name => value}
  File.open(File.expand_path("~") + "/.apollo.yaml", "w") { |f| f.write(data.to_yaml) }
end

def read_config(name)
  file = File.expand_path("~") + "/.apollo.yaml"
  if File.exist? file
    data = open(file) { |f| YAML.load(f) }
    begin
      data[name]
    rescue => e
    end
  end
end

class RequestHandler < EventMachine::Connection
  attr_reader :args

  def initialize(args)
    @args = args
  end

  def post_init
    if @args[0] == "--addUser"

    elsif @args[0] == "--init"
      ssh_pub = File.expand_path("~") + "/.ssh/id_rsa.pub"
      if File.exist? ssh_pub
        file = File.new(ssh_pub, "r")
        data = ""
        while (line = file.gets)
          data += line
        end
        file.close

        send_data read_config("APOLLO_USER") + "#--addSSH*" + data
      end
    else
      send_data read_config("APOLLO_USER") + "#" + @args.join("*")
    end
  end

  def receive_data(data)
    puts data
  end

  def unbind
    EventMachine::stop_event_loop
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

  if args.length != 2 && args[0] != "--init"
    print_usage
    return 0
  end

  if args[0] != "--addUser" && args[0] != "--createRepo" && args[0] != "--init"
    print_usage
    return 0
  end

  if args[0] == "--init"
      ssh_pub = File.expand_path("~") + "/.ssh/id_rsa.pub"
      if File.exist? ssh_pub

        write_config("APOLLO_USER", "testuser:test")

      else
        puts "Error: please run ssh-keygen first"
        return 0
      end

    end

  if args[0] != "--addUser"
    if read_config("APOLLO_USER").nil?
      puts "Error: please run --addUser first"
      return 0
    end

    apollo_user = read_config("APOLLO_USER").split(":")
    if apollo_user.length != 2
      puts "Error: please run --addUser to add a valid user"
      return 0
    end
  end

  if args[0] == "--addUser"
    if args[1].split(":").length != 2
      puts "Error: please add a valid user and password pair <user name>:<password>"
    else
      write_config("APOLLO_USER", args[1])
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
    EventMachine.connect '50.112.193.83', 8081, RequestHandler, args
    #EventMachine.connect '127.0.0.1', 8081, RequestHandler, args
  }
end

exit(main(ARGV) || 1)
