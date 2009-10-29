require 'rubygems'
require 'hpricot'

#
# Regular-expression based compiler for HQUERY source
#
module Hquery
  class Compiler
    def initialize(doc)
      @doc = doc
      @rhash = {}
      @ahash = {}
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end

    def compile(hquery_source, compiled_filename)
      (interpreted_src, precompile_src) = hquery_source.split(/^\# ENDPRECOMPILED.*$/).reverse
      # if it exists, we simply eval the code for precompile
      eval(precompile_src) if precompile_src
      # then we move on to interpret each "select ... do end" segment
      interpreted_src.to_s.scan(/^select .*?^end$/m).each do |code|
        lines = code.split(/[\r\n]+/)
        case lines.pop && lines.shift
        when /^select \"([^\"]+)\", (.+)\s*(do|\{)\s*\|\s*(\w+)\s*,\s*([^\|]+)\s*,\s*(\w+)\s*\|/
          (selector, list, ele, item, index) = [$1, $2, $4, $5, $6]
          logger.debug "selector #{selector} (#{ele}), list #{list} (#{item}, #{index})"
          if li = (@doc/selector).first
            ul = (@doc/selector).first.parent
            lines.collect {|line| parse(line, selector, ele, list, item) }
            ul.html "<% (#{list}).each_with_index do |#{item}, #{index}| %>\n#{li}\n<% end %>"
          else
            logger.error "compile: #{selector.inspect} does not exist!"
          end
        when /^select \"([^\"]+)\", (.+)\s*(do|\{)\s*\|\s*(\w+)\s*,\s*([^\|]+)\s*\|/
          (selector, list, ele, item) = [$1, $2, $4, $5]
          logger.debug "selector #{selector} (#{ele}), list #{list} (#{item})"
          if li = (@doc/selector).first
            ul = (@doc/selector).first.parent
            lines.collect {|line| parse(line, selector, ele, list, item) }
            ul.html "<% (#{list}).each do |#{item}| %>\n#{li}\n<% end %>"
          else
            logger.error "compile: #{selector.inspect} does not exist!"
          end
        when /^select \"([^\"]+)\"\s*(do|\{)\s*\|\s*(\w+)\s*\|/
          (selector, ele) = [$1, $3]
          logger.debug "selector #{selector} (#{ele})"
          lines.each {|line| parse(line, selector, ele, nil, nil) }
        when /^\s*\#/, /^\s*$/
          logger.debug "ignoring comment: #{code}"
        else
          raise "compile: cannot interpret: \n#{code}"
        end
      end

      interpreted_src.to_s.scan(/^remove.*$/).each do |code|
        logger.debug "interpreting: #{code.inspect}"
        case code
        when /^remove \"([^\"]+)\"\s*(\b(if|unless)\b\s*(.+))\s*/
          (selector, condition, clause, bool) = [$1, $2, $3, $4]
          clause = (clause == 'if' ? 'unless' : 'if')
          tagname = unique_placeholder_tagname
          (@doc/selector).wrap("<#{tagname}></#{tagname}>")
          @rhash[tagname] = "#{clause} #{bool}"
        when /^remove \"([^\"]+)\"\s*/
          selector = $1
          logger.debug "removing #{selector} unconditionally"
          (@doc/selector).remove
        else
          raise "compile: cannot interpret: \n#{code}"
        end
      end

      html_string = @doc.to_html
      @rhash.keys.each do |tagname|
        html_string = html_string.gsub("/#{tagname}", '% end %').gsub("#{tagname} /", "% #{@rhash[tagname]} %").gsub(tagname, "% #{@rhash[tagname]} %")
      end
      @ahash.each do |(key,value)|
        html_string = html_string.gsub(key, "<%= #{value} %>")
      end

      File.open(compiled_filename, "w") do |f|
        f.write html_string
        # asking the generated template to delete itself is 
        # only useful for developing & testing this compiler
        f.write "<% File.delete(#{compiled_filename.inspect}) %>" if ENV['HQUERY_DEBUG_COMPILE']
      end
    end

    def parse(line, selector, ele, list, item)
      case line
      when /^\s*#{ele}\.html \"([^\"]+\[@(\w+)\])\", (.+)/, /^\s*#{ele}\.attr \"([^\"]+)\", \"([^\"]+)\", (.+)/
        (subselector, attribute, code) = [$1, $2, $3]
        logger.debug "parsing: '#{selector} #{subselector}'"
        selected = (@doc/"#{selector} #{subselector}").compact
        logger.error "compile: #{selector.inspect} > #{subselector.inspect} does not exist!" unless selected.length > 0
        selected.each do |html|
          # logger.debug "set attribute #{html.name}.#{attribute}=<%= #{code} %>"
          html.raw_attr(attribute, "<%= #{code} %>")
        end
      when /^\s*#{ele}\.html \"([^\"]+)\", (.+)/
        (subselector, code) = [$1, $2]
        logger.debug "parsing: '#{selector} #{subselector}'"
        selected = (@doc/"#{selector} #{subselector}").compact
        logger.error "compile: #{selector.inspect} > #{subselector.inspect} does not exist!" unless selected.length > 0
        selected.each do |html|
          # logger.debug "set element #{html.name}=<%= #{code} %>"
          html.html "<%= #{code} %>"
        end
      when /^\s*#{ele}\.html (.+)/
        code = $1
        logger.debug "parsing: '#{selector}'"
        selected = (@doc/"#{selector}").compact
        logger.error "compile: #{selector.inspect} does not exist!" unless selected.length > 0
        selected.each do |html|
          # logger.debug "set element #{html.name}=<%= #{code} %>"
          html.html "<%= #{code} %>"
        end
      when /^\s*#{ele}\.attr \"([^\"]+)\", (.+?)\s*(\b(if|unless)\b\s*(.+))\s*/
        (attribute, value, condition, clause, bool) = [$1, $2, $3, $4, $5]
        logger.debug "parsing: '#{selector}'"
        selected = (@doc/"#{selector}").compact
        logger.error "compile: #{selector.inspect} does not exist!" unless selected.length > 0
        selected.each do |html|
          tagname = unique_placeholder_tagname
          outputs = []
          if oldvalue = html.raw_attributes && html.raw_attributes[attribute]
            outputs << "#{attribute}=#{oldvalue.inspect}"
          else
            outputs << ""
          end
          outputs << "#{attribute}=#{value}"
          outputs.reverse! if clause == "if"
          @ahash["#{attribute}=\"#{tagname}\""] = "((#{bool}) ? (#{outputs.first.inspect}) : (#{outputs.last.inspect}))"
          html.raw_attr( attribute, tagname)
        end
      when /^\s*#{ele}\.attr \"([^\"]+)\", (.+)/
        (attribute, code) = [$1, $2]
        logger.debug "parsing: '#{selector}'"
        selected = (@doc/"#{selector}").compact
        logger.error "compile: #{selector.inspect} does not exist!" unless selected.length > 0
        selected.each do |html|
          # logger.debug "set attribute #{html.name}.#{attribute}=<%= #{code} %>"
          html.raw_attr(attribute, "<%= #{code} %>")
        end

      when /^\s*#{ele}\.remove \"([^\"]+)\"\s*(\b(if|unless)\b\s*(.+))\s*/
        (subselector, condition, clause, bool) = [$1, $2, $3, $4]
        clause = (clause == 'if' ? 'unless' : 'if')
        tagname = unique_placeholder_tagname
        (@doc/"#{selector} #{subselector}").wrap("<#{tagname}></#{tagname}>")
        @rhash[tagname] = "#{clause} #{bool}"
      when /^\s*#{ele}\.remove \"([^\"]+)\"\s*/
        subselector = $1
        logger.debug "removing \"#{selector} #{subselector}\" unconditionally"
        (@doc/"#{selector} #{subselector}").remove

      when /^\s*\#/, /^\s*$/, /^\s*debug_schema\s*$/
        logger.debug "ignoring comment: #{line}"
      else
        raise "parse: cannot understand #{line} with #{[selector, ele, list, item].inspect}"        
      end
    end

    def unique_placeholder_tagname
      tagname = "hquery#{Time.now.to_f}#{rand(1000)}"
      @rhash[tagname] ? unique_placeholder_tagname : tagname
    end

    class << self
      def compile(basedir)
        Dir[File.join(basedir, "**/*.hquery")].each do |hquery_filename|
          template_filename = [hquery_filename.gsub(/hquery$/i, 'hquery.html'), hquery_filename.gsub(/hquery$/i, 'html')].find {|s| File.exists?(s)}
          compiled_filename = hquery_filename.gsub(/hquery$/i, 'html.erb')
          if !File.exists?(compiled_filename) || File.mtime(compiled_filename) < File.mtime(hquery_filename) || File.mtime(compiled_filename) < File.mtime(template_filename) || ENV['HQUERY_COMPILE']
            puts "Compiling #{hquery_filename} -> #{compiled_filename} ..."
            hquery_source = IO.read(hquery_filename)
            doc = Hpricot(IO.read(template_filename))
            Hquery::Compiler.new(doc).compile(hquery_source, compiled_filename)
          else
            puts "Skipping #{hquery_filename} (#{compiled_filename} is newer)"
          end
        end
      end
    end
  end
end
if __FILE__ == $0
  require 'logger'
  Hquery::Compiler.class_eval do
    def logger
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end
      @logger
    end
  end
  Hquery::Compiler.compile(*ARGV)
end