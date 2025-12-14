# frozen_string_literal: true

require 'rake/testtask'

task default: %w[ttt]

desc 'Run Tic Tac Toe (default)'
task :ttt do
  ruby 'ttt.rb'
end

desc 'Run tests'
task :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end
