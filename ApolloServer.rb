require 'eventmachine'
require 'fileutils'

module ApolloServer
  @@post_receive =
"#!/bin/bash -l
echo source code has been trasmitted successfully
GIT_WORK_TREE=/home/ubuntu/www/%s/%s
export GIT_WORK_TREE
echo checking code out to deployment folder
git checkout -f
if [ -f $GIT_WORK_TREE/package.json ];
then
  echo installing dependencies
  cd $GIT_WORK_TREE
  sudo npm install
fi
echo allocating resources
rs=$(ruby ~/nebula/launchy.rb %s %s %s)
rs_splitted=$(echo $rs | tr \"#\" \"\n\")
i=0
for x in $rs_splitted
do
  rs_array[$i]=$x
  let \"i += 1\"
done

if [ \"${#rs_array[@]}\" = 1 ]
then
  echo Error: launchy returns an unexpected result.
else
  export WEB_PORT=${rs_array[0]}
  echo starting instance
  ruby ~/nebula/restart.rb ${rs_array[1] k
  node $GIT_WORK_TREE/app.js &> /dev/null &
  echo starting web server
  sudo /etc/init.d/nginx restart > /dev/null &
  echo The repository has been deployed to http://${rs_array[1]}
  exit 1
fi
"

  def post_init
    puts "-- someone connected to the echo server!"
  end

  def receive_data data
    puts "=====>#{data}"
    begin
    request_params = data.split("#")

    if request_params.length != 2
      send_data "Invalid request"
      close_connection_after_writing
      return
    end

    credentials = request_params[0].split(":")
    if credentials.length != 2
      send_data "Invalid request"
      close_connection_after_writing
      return
    end

    command_params = request_params[1].split("*")
    if command_params.length != 2
      send_data "Invalid request"
      close_connection_after_writing
      return
    end

    if request_params[0] != "testuser:test"
      send_data "Invalid username or password"
      close_connection_after_writing
      return
    end

    if command_params[0] == "--createRepo"
      unless command_params[1].end_with? ".git"
        git_repo = command_params[1] + ".git"
      end

      file = File.expand_path('~') + '/repository/' + git_repo
      if File.exist? file
        send_data "Repository #{git_repo} has already existed"
        close_connection_after_writing
        return
      end

      FileUtils.mkdir_p file
      system("git --bare init #{file}")
      #send_data "Repository #{command_params[1]} is created successfully"
      work_tree = "/home/ubuntu/www/#{credentials[0]}/#{command_params[1]}"
      unless File.exist? work_tree
        FileUtils.mkdir_p work_tree
      end

      post_receive = file + '/hooks/post-receive'
      File.open(post_receive, 'w') do |f|
        f.puts @@post_receive % [credentials[0], command_params[1], credentials[0], command_params[1], work_tree]
      end

      system("chmod +x #{post_receive}")

      send_data "--pongRepo*" + file
      close_connection_after_writing
      return
    end

    if command_params[0] == "--addSSH"
      send_data "Initialized Nebula"
      close_connection_after_writing

      filename = File.expand_path("~") + "/.ssh/authorized_keys"

      if File.exist? filename
        data = File.read filename
        if data.include? command_params[1]
          return
        end
      end
      File.open(filename, 'a') do |file|
        file.puts command_params[1]
      end
    end

      if command_params[0] == "--resetUrl"
        puts command_params[1]
        domains = command_params[1].split('=')
        if system("ruby ~/nebula/reset_url.rb #{domains[0]} #{domains[1]}")
          send_data "Reset url from #{domains[0]} to #{domains[1]} successfully"
        else
          send_data "Failed to reset url from #{domains[0]} to #{domains[1]} "
        end
        close_connection_after_writing
      end

    rescue => e
      puts e
      send_data "Internal error happened"
      close_connection_after_writing
    end
    close_connection if data =~ /quit/i
  end

  def unbind
    puts "-- someone disconnected from the echo server!"
  end
end

# Note that this will block current thread.
EventMachine.run {
  EventMachine.start_server "0.0.0.0", 8081, ApolloServer
}
