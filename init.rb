require 'hpricot_query'
ActionView::Template.register_template_handler "hquery", HpricotQuery
# scan directories for .hquery.html, and create debugger .hquery equivalent files
Dependencies.explicitly_unloadable_constants << 'HpricotQuery'