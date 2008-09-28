# Install hook code here
require 'config/environment'
puts "Copying files..."
Dir[File.join(File.dirname(__FILE__), "payload", '*')].each do |filename|
  dest = File.join(RAILS_ROOT, "public", (filename =~ /js$/ ? "javascripts" : "stylesheets"));
  puts "Copying #{filename} to #{dest} ..."
  FileUtils.cp_r(filename, dest)
end
puts "Files copied - Installation complete!"
