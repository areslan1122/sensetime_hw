task :default => :test3

desc 'task1'
task :test1 do
  sh 'echo task1'
end

desc 'task2'
task :test2 => :test1 do
  sh 'echo task2'
end

desc 'task3'
task :test3 => [:test1, :test2] do
  sh 'echo task3'
end

task :test4 => :test5 do
  sh 'echo task4'
end

