require 'rubygems'
require File.join(File.dirname(__FILE__), '../lib/hquery/element')
require File.join(File.dirname(__FILE__), '../lib/hquery/compiler')

desc "Seeks out .hquery files and generate .html.erb equivalents"
task :hquery do
  Hquery::Compiler.class_eval do
    def logger
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end
      @logger
    end
  end
  Hquery::Compiler.compile('.')
end
