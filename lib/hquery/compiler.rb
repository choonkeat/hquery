require 'hpricot'
require 'cgi'

#
# Regular-expression based compiler for HQUERY source
#
module Hquery
  class Compiler
    def initialize(doc)
      @doc = doc
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end

    def compile(hquery_source, compiled_filename)
      (interpreted_src, precompile_src) = hquery_source.split(/^\# ENDPRECOMPILED.*$/).reverse
      # if it exists, we simply eval the code for precompile
      eval(precompile_src) if precompile_src
      # then we move on to interpret each "select ... do end" segment
      interpreted_src.scan(/^select .*?^end$/m).each do |code|
        lines = code.split(/[\r\n]+/)
        case lines.pop && lines.shift
        when /^select \"([^\"]+)\"\s*(do|\{)\s*\|\s*(\w+)\s*\|/
          (selector, ele) = [$1, $3]
          logger.debug "selector #{selector} (#{ele})"
          lines.each {|line| parse(line, selector, ele, nil, nil) }
        when /^select \"([^\"]+)\", (.+)\s*(do|\{)\s*\|\s*(\w+)\s*,\s*(\w+)\s*\|/
          (selector, list, ele, item) = [$1, $2, $4, $5]
          logger.debug "selector #{selector} (#{ele}), list #{list} (#{item})"
          li = (@doc/selector).first
          ul = (@doc/selector).first.parent
          lines.collect {|line| parse(line, selector, ele, list, item) }
          ul.html "<% (#{list}).each do |#{item}| %>\n#{li}\n<% end %>"
        when /^\s*\#/, /^\s*$/
          logger.debug "ignoring comment: #{code}"
        else
          raise "compile: cannot interpret: \n#{code}"
        end
      end

      interpreted_src.scan(/^remove.*$/).each do |code|
        logger.debug "interpreting: #{code.inspect}"
        case code
        when /^remove \"([^\"]+)\"\s*((if|unless)\s*(.+))\s*/
          (selector, condition, clause, bool) = [$1, $2, $3, $4]
          clause = (clause == 'if' ? 'unless' : 'if')
          placeholder = "hquery#{Time.now.to_f}"
          (@doc/selector).wrap("<#{placeholder}></#{placeholder}>")
          @doc = Hpricot(@doc.to_html.gsub("/#{placeholder}", '% end %').gsub(placeholder, "% #{clause} #{bool} %"))
        when /^remove \"([^\"]+)\"\s*/
          selector = $1
          logger.debug "removing #{selector} unconditionally"
          sleep 3
          (@doc/selector).remove
        else
          raise "compile: cannot interpret: \n#{code}"
        end
      end

      File.open(compiled_filename, "w") do |f|
        f.write @doc.to_s
        # asking the generated template to delete itself is 
        # only useful for developing & testing this compiler
        f.write "<% File.delete(#{compiled_filename.inspect}) %>" if ENV['HQUERY_DEBUG_COMPILE']
      end
    end
    
    def parse(line, selector, ele, list, item)
      case line
      when /^\s*#{ele}\.html \"([^\"]+\[@(\w+)\])\", (.+)/, /^\s*#{ele}\.attr \"([^\"]+)\", \"([^\"]+)\", (.+)/
        (subselector, attribute, code) = [$1, $2, $3]
        logger.info "parsing: '#{selector} #{subselector}'"
        selected = (@doc/"#{selector} #{subselector}")
        selected.each do |html|
          logger.info "set attribute #{html.name}.#{attribute}=<%= #{code} %>"
          html.raw_attr(attribute, "<%= #{code} %>")
        end
      when /^\s*#{ele}\.html \"([^\"]+)\", (.+)/
        (subselector, code) = [$1, $2]
        logger.info "parsing: '#{selector} #{subselector}'"
        selected = (@doc/"#{selector} #{subselector}")
        selected.each do |html|
          logger.info "set element #{html.name}=<%= #{code} %>"
          html.html "<%= #{code} %>"
        end
      when /^\s*#{ele}\.html (.+)/
        code = $1
        logger.info "parsing: '#{selector}'"
        selected = (@doc/"#{selector}")
        selected.each do |html|
          logger.info "set element #{html.name}=<%= #{code} %>"
          html.html "<%= #{code} %>"
        end
      when /^\s*#{ele}\.attr \"([^\"]+)\", (.+)/
        (attribute, code) = [$1, $2]
        logger.info "parsing: '#{selector}'"
        selected = (@doc/"#{selector}")
        selected.each do |html|
          logger.info "set attribute #{html.name}.#{attribute}=<%= #{code} %>"
          html.raw_attr(attribute, "<%= #{code} %>")
        end
      when /^\s*\#/, /^\s*$/, /^\s*debug_schema\s*$/
        logger.debug "ignoring comment: #{line}"
      else
        raise "parse: cannot understand #{line} with #{[selector, ele, list, item].inspect}"        
      end
    end
  end
end