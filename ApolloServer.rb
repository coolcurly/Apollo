require 'eventmachine'
require 'fileutils'

 module ApolloServer
   def post_init
     puts "-- someone connected to the echo server!"
   end

   def receive_data data
     send_data ">>>you sent: #{data}"
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

     command_params = request_params[1].split("")
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
       p FileUtils.mkdir_p File.expand_path('~') + '/repository/' +  command_params[1]
       close_connection_after_writing
       return
     end

     close_connection if data =~ /quit/i
   end

   def unbind
     puts "-- someone disconnected from the echo server!"
  end
end

# Note that this will block current thread.
EventMachine.run {
  EventMachine.start_server "127.0.0.1", 8081, ApolloServer
}
