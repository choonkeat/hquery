ActionView::Template.register_template_handler :hquery, Hquery::Handler
ActionView::Template.register_template_handler :html, Hquery::HtmlHandler
Hpricot::Elem.send(:include, Hquery::Element)
