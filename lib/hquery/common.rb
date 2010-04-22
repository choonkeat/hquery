module Hquery
  module Common
    def html_template_filename(filename)
      possible_names = [
        filename.gsub(/(.\w+).hquery$/i, '\1'),    # file.html.hquery renders file.html *preferred*
        filename.gsub(/hquery$/i, 'hquery.html'),  # file.hquery      renders file.hquery.html
        filename.gsub(/hquery$/i, 'html'),         # file.hquery      renders file.html
      ]
      possible_names.find {|s| File.exists?(s)}
    end
  end
end