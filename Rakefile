#!/usr/bin/env rake

task :default => :test

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.ruby_opts << "-rubygems"
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
