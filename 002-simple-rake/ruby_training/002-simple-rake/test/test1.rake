task :task1 do
  sh 'echo task1'
end

task :task2 => :task1 do
  sh 'echo task2'
end

task :task3 => :task2 do
  sh 'echo task3'
end
