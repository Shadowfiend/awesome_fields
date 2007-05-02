require 'magic_fields'
ActionView::Helpers::FormBuilder.send :include, MagicFields::MagicFieldHelpers
