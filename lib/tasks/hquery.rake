desc "Seeks out .hquery files and generate .html.erb equivalents"
task :hquery => :environment do
  Hquery::Compiler.class_eval do
    def logger
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end
      @logger
    end
  end
  Hquery::Compiler.compile('app/views')
end
