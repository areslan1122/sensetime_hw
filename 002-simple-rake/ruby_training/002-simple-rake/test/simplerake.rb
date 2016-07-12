#!usr/bin/env ruby

require 'singleton'
require 'optparse'



options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: ./simplerake.rb [option] srake_file [task]'
  options[:desc] =false
  options[:rake] =false
  opts.on('-h','','print help') do
    puts opts
    exit
  end
  
  opts.on('-T RAKEFILENAME','','list tasks') do |value|
    options[:descfile] = value
    options[:desc] = true
  end
  
end.parse!





class Task
  include Singleton

    @@newdesc =nil 
  def initialize
    @task = {}
    @desc = {}
    @blo = {}
    @status = {}
  end

  def add_desc(str)
    @@newdesc = str
  end


  def add_task(txt,&block)
    
    if txt.is_a?(Symbol)
       @task[txt] = nil
       @status[txt] = false
      if block.class == Proc
          @blo[txt] = block.call
      else
          @blo[txt] = nil
      end
      if @@newdesc == nil
         @desc[txt] = ''   
      else
         @desc[txt] = @@newdesc
         @@newdesc = nil
      end 

    else
      txt.each do |key,value|
        @task[key] = value
        @status[key] = false
        if block.class == Proc
          @blo[key] = block.call
        else
          @blo[key] = nil
        end
        if @@newdesc == nil
          @desc[key] = ''
        else
          @desc[key] = @@newdesc
          @@newdesc = nil
        end
      end
    end  
  end


  def run_desc
    @desc.each do |key,value|
      if key != :default
         puts "#{key}          ##{value}"
      end
    end
  end


  def run_rake(str)
#    @task.each do |key,value|
#     puts "#{key}     #{value}"
#    end
#    puts "'''''''''''''"
#    @blo.each do |key,value|
#     puts"#{key}      #{value}"
#    end
    if @task[str] == nil
      if @status[str] == false
        puts @blo[str]
        @status[str] = true
      end
    else
      if @task[str].class ==Array
        @task[str].each do |value|
          run_rake(value)
        end
      else
        aa = @task[str]
        run_rake(aa)
      end
      puts @blo[str] 
    end
  end

end



def task(a,&block)
  Task.instance.add_task(a,&block)
end

def desc(str = '')
  Task.instance.add_desc(str)
end

def sh(str)
  `#{str}`
end


#load "#{options[:descfile]}"

if options[:desc]
  load "#{options[:descfile]}"
  Task.instance.run_desc
else
  load "#{ARGV[0]}"
  if ARGV.size == 1
     Task.instance.run_rake(:default)
  else
     Task.instance.run_rake(ARGV[1].to_sym)
  end
end




