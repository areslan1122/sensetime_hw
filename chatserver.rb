#!/usr/bin/env ruby
# Run with
# $ chmod +x chat.rb && ./chat.rb
# or
# $ ruby chat.rb
require 'socket'
require 'thread'
require 'logger'


logger = Logger.new(STDOUT)
logger.level = Logger::INFO

class User
attr_accessor :name, :socket, :thread
def initialize(name, socket, thread)
@name = name
@socket = socket
@thread = thread
end
end
$users = []
$users_mutex = Mutex.new
PORT = 4625
HOST = "127.0.0.1"
server = TCPServer.new(HOST,PORT)
puts "[#{Time.now}]: Server started...\nListening on port #{PORT}\n"
loop do
Thread.start(server.accept) do |client|
client.puts "Welcome to AkChat!"
client.puts "Please login!\n"
client.write "Login: "
username = client.gets.chomp
u = User.new(username, client, Thread.current)
$users_mutex.synchronize do
$users.each do |us|
if us.name == username
client.puts "This username is already taken."
client.close
Thread.stop
else
us.socket.puts "\n### #{username} joined to the conversation ###"
us.socket.write "[#{us.name}]: "
end
end
$users << u
client.puts "Welcome aboard #{username}!"
puts "[#{Time.now}]: User #{username} signed in..."
$users.each do |us|
  puts "\t#{us.name}"
end
if ($users.count > 1)
client.puts "We have #{$users.count} users logged in:"
$users.each do |us|
client.puts "\t#{us.name}"
end
end
end


loop do
client.write "[#{username}]: "
msg = client.readline.chomp
if (msg == "quit" || msg == "q")
$users_mutex.synchronize do
$users -= [u]
end
client.close
puts "[#{Time.now}]: #{username} quited from chat"
$users_mutex.synchronize do
$users.each do |us|
us.socket.puts "\n### #{username} quited from the conversation ###"
us.socket.write "[#{us.name}]: "
end
end
Thread.kill(Thread.current)
end

puts "[#{username}]:#{msg}"
logger.info("#{msg}")
$users_mutex.synchronize do
$users.each do |us|
if (us.name != username)
# puts "[#{Time.now}]: Broadcasting message '#{msg}' from #{username} to #{us.name}."
 
us.socket.puts "\n[#{username}]: #{msg}"
us.socket.write "[#{us.name}]: "
end
end
end
end
end
end
