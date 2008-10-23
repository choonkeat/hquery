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
  Dir["app/views/*/*.hquery"].each do |hquery_filename|
    template_filename = hquery_filename.gsub(/hquery$/i, 'html')
    compiled_filename = hquery_filename.gsub(/hquery$/i, 'html.erb')
    if !File.exists?(compiled_filename) || File.mtime(compiled_filename) < File.mtime(hquery_filename) || ENV['HQUERY_COMPILE']
      puts "Compiling #{hquery_filename} -> #{compiled_filename} ..."
      hquery_source = IO.read(hquery_filename)
      doc = Hpricot(IO.read(template_filename))
      Hquery::Compiler.new(doc).compile(hquery_source, compiled_filename)
    else
      puts "Skipping #{hquery_filename} (#{compiled_filename} is newer)"
    end
  end
end
