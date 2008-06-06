require 'awesome_fields'
ActionView::Helpers::FormBuilder.send :include, AwesomeFields::AwesomeFieldHelpers
ActionView::Helpers::FormHelpers.send :include, AwesomeFields::LinedBuilderHelpers
