# frozen_string_literal: true

require 'rake/testtask'

task default: %w[wwwttt]

desc 'Run Web-based Tic Tac Toe (default)'
task :wwwttt do
  ruby 'wwwttt.rb'
end

desc 'Run tests'
task :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end
