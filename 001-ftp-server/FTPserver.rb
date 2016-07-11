#!/usr/bin/env ruby

require 'socket'
require 'thread'
require 'logger'
require 'optparse'



options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = 'here is help messages of the command line'
  
  opts.on('-h','','print help') do
    puts opts
    exit
  end
  opts.on('-p PORT','--port=PORT','listen port') do |value|
    options[:port] = value
  end

  opts.on('-n','--host=HOST','binding address') do |value|
    options[:host] = value
  end
  opts.on('-d','--dir=DIR' ,'change current directort') do |value|
    options[:dir] = value
  end

  if options[:port] == nil
     options[:port] = "4625"
  end

  if options[:host] == nil
     options[:host] = "localhost"
  end

  if options[:dir] == nil
    options[:dir] = Dir.pwd
  end
end.parse!


logger = Logger.new(STDOUT)
logger.level = Logger::INFO

class User
  attr_accessor :name, :socket, :thread
   
  @@usercount = 0 
  def self.usercount
    @@usercount
  end
  def initialize(name, socket, thread)
    @name = name
    @socket = socket
    @thread = thread
    @@usercount += 1
  end
end

$users = []
$pass = {}
$users_mutex = Mutex.new
PORT = options[:port].to_i
HOST = options[:host]
server = TCPServer.new(HOST,PORT)
#serversocket = TCPServer.new("0.0.0.0",8000)
Dir.chdir(options[:dir])
puts "[#{Time.now}]: Server started...\nListening on PORT #{PORT} | HOST #{HOST} | DIR : #{Dir.pwd} "


loop do
  Thread.start(server.accept) do |client|
    client.puts "Welcome to FTPserver!"
    client.puts "332 Need account for login\n"
    client.puts "Please use command: USER <username> <CRLF>"
    client.write "Login: "
    command = client.gets.chomp.split
    logger.info "#{command}"
    
    while (command[0] != "USER" || command[1] == nil) do
      if command[0] != "USER"
        client.puts"500 Syntex error , command unrecognized"
      else
        client.puts"504 Command not implemented for that parameter"
      end
      client.puts"Please use command: USER <username> <CRLF>"
      client.write"Login: "
      command = client.gets.chomp.split
      logger.info "#{command}"
    end 

    username = command[1]
    u = User.new(username, client, Thread.current)
    $users_mutex.synchronize do
      $users.each do |us|
        if us.name == username
          client.puts "This username is already taken."
          client.close
          Thread.stop
        end
      end
      client.puts "331 User name okay, need password"
      client.puts "please use command:   PASS <password> <CRLF>"
      client.write"Password:"
      password = client.gets.chomp.split
      logger.info "#{password}"

      while (password[0] != "PASS" || password[1] == nil) do
        if password[0] != "PASS" 
          client.puts"500 Syntex error , commamd unrecopnized"
        else
          client.puts"504 Command not implemented for that parameter"
        end
        client.puts"Please use command:  PASS <password> <CRLF>"
        client.write"Password:"
        password = client.gets.chomp.split
        logger.info "#{password}"
      end
      
      if $pass[username] == nil
        $pass[username] = password[1]
      end

      while ($pass[username] != password[1]) do
        client.puts "504 Command not implemented for that parameter"
        client.write "password:"
        password = client.gets.chomp.split
        logger.info "#{password}"
      end

      $users << u
      client.puts "Welcome aboard #{username}!"
      logger.info"[User <#{username}> signed in..."
    #  serversocket = TCPServer.new("0.0.0.0" ,PORT + User.usercount)    #build data server
      
      if ($users.count > 1)
        client.puts "We have #{$users.count} users logged in:"
      end
    end

    loop do
      client.write "[#{username}]: "
      msg = client.readline.chomp.split
      logger.info "#{msg}"
      if (msg[0] == "QUIT")
        client.puts "200 Command okay"
        $users_mutex.synchronize do
          $users -= [u]
        end
        client.close
        logger.info"#{username} quited from server"
        Thread.kill(Thread.current)

      elsif(msg[0] == "PWD")
        client.puts"#{Dir.pwd}"
        client.puts"200 Command okay"

      elsif(msg[0] == "CWD")
        if File.directory?(msg[1])
          Dir.chdir(msg[1])
          client.puts "200 Command okay"
        else
          client.puts "504 Command not implemented for that parameter"
        end
                  
      elsif(msg[0] == "LIST" && msg[1] != nil)
        if File.directory?(msg[1])
          client.puts"#{Dir.entries(msg[1])}"
          client.puts"200 Command okay"
        elsif File.file?(msg[1])
          client.puts"#{IO.readlines(msg[1])}"
          client.puts"200 Command okay"
        else
          client.puts "504 Command not implemented for that parameter"
        end
             
      elsif(msg[0] == "LIST" && msg[1] == nil)
         client.puts "#{Dir.entries(Dir.pwd)}"
         client.puts"200 Command okay"
      
      elsif(msg[0] == "STOR")
         if msg[1]!=nil
           msg[1] = "#{Dir.pwd}/#{msg[1]}"
           serversocket = TCPServer.new("0.0.0.0",PORT+User.usercount)
           client.puts"225 Data connection open"
           client.puts"host :localhost, PORT: #{PORT + User.usercount}"
        
           datasocket = serversocket.accept
           # require 'pry'
         
           # clientdata.puts" start transport file"
           
         
           # clientdata.puts""
           # clientfile = IO.readlines("#{msg[1]}")
           client.puts "125 Data connection already open; transfer starting"
           clientfile = datasocket.read
           # clientdata.puts clientfile
           # filename = msg[1][msg[1].rindex("/")..-1]
           serverfile = File.open("#{msg[1]}","w+")


           serverfile.write(clientfile)
           serverfile.close
          
           # clientdata.puts""
           # clientdata.puts"file transport succesble"
           # clientdata.close

           client.puts("226 Closing data connection. Requested file action successful")
           serversocket.close
         else
           client.puts "504 Commend not implemented for that parameter"
         end        

      elsif(msg[0] == "RETR")
         
        if File.file?(msg[1])
          client.puts"225 Data connection open"
          client.puts"host :localhost  PORT:#{PORT + User.usercount}"
          serversocket = TCPServer.new("0.0.0.0", PORT + User.usercount)
          datasocket = serversocket.accept
          serverfile = File.open("#{msg[1]}","r")
          client.puts"125 Data connection already open ; transfer starting"
          datasocket.write(serverfile.read)
          datasocket.close
      #    clientdata = serverdata.accept
      #    clientdata.puts "transport start"
      #    clientdata.puts""
      #    serverfile = IO.readlines("#{msg[1]}")
      #    clientdata.puts serverfile
      #    clientdata.puts ""
      #    clientdata.puts "transport done"
      #    clientdata.close

          client.puts"226 Closing data connection.Requested file action successful"
          serversocket.close

        else
          client.puts"550 Requested action not taken. File unavailable"  
        end
               

      else
        client.puts"500 Syntax error , command unrecognized"
      end
         
         
    end
  end
end
