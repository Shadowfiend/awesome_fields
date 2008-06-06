require 'awesome_fields'
ActionView::Helpers::FormBuilder.send :include, AwesomeFields::AwesomeFieldHelpers
ActionView::Base.send :include, AwesomeFields::LinedBuilderHelpers
