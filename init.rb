ActionView::Template.register_template_handler :hquery, Hquery::Handler
Hpricot::Elem.send(:include, Hquery::Element)
