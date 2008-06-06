module AwesomeFields
  # This class builds form fields wrapped in divs with CSS class form_line and
  # appropriate labels.
  class LinedBuilder < ActionView::Helpers::FormBuilder
    def text_field(label, options = {})
      labeled_field(label, options) { super label, options }
    end

    def password_field(label, options = {})
      labeled_field(label, options) { super label, options }
    end

    def file_field(label, options = {})
      labeled_field(label, options) { super label, options }
    end

    def check_box(label, options = {})
      labeled_field(label, options) { super label, options }
    end

    def text_area(label, options = {})
      if options[:long]
        options.reverse_merge!({ :rows => 20, :cols => 70 })
      else
        options.reverse_merge!({ :rows => 10, :cols => 30 })
      end

      labeled_field(label, options) { super label, options }
    end

    def date_select(label, options = {})
      options.merge!({ :order => [ :month, :day, :year ] })

      labeled_field(label, options) { super label, options }
    end
    alias_method :date_field, :date_select

    def select(label, choices, options = {}, html_options = {})
      err = error_on label, options

      html_options.reverse_merge!({ :size => 5 }) unless html_options[:multiple].nil?

      @template.content_tag( 'div',
        (err ? err : '') + label_tag( label, options ) +
          super,
        :class => err ? 'form_line_with_errors' : 'form_line' )
    end

    def submit_button(label = 'submit', options = {})
      @template.content_tag 'div',
        @template.submit_tag(label.to_s.humanize),
        :class => 'form_buttons'
    end

   protected
    # Produces a labeled field given the label, the options, and a block that
   # will generate the appropriate field content.
    def labeled_field(attr, options, &content_gen)
      err = error_on attr, options
      after = options.delete(:after) || ''

      @template.content_tag 'div',
        (err ? err : '') + label_tag(attr, options) + content_gen.call + after,
        :class => (err ? 'form_line_with_errors' : 'form_line')
    end

    # Produces the appropriate label tag for the given attribute, including
    # returning nothing if the :no_label option was passed and using the :label
    # option instead of the attribute name if it was provided.
    def label_tag(attr_name, options = {})
      return '' if options.delete(:no_label)

      @template.content_tag 'label',
        "#{(options.delete(:label) || attr_name.to_s.humanize)}:",
        :for => "#{@object_name}_#{attr_name}",
        :class => (options[:long] ? 'long' : '')
    end

    # Produces a formatted version of the error on the given attribute. If a
    # label was provided, includes that instead of the attribute name.
    # Prefixes the error with the label or the attribute name and postfixes it
    # with a `.'. Returns a div string with the class field_error.
    def error_on(attr, options)
      errors = @object.errors[attr]
      return nil unless errors

      errors = errors.to_sentence if errors.respond_to?(:to_sentence)

      @template.content_tag 'div',
        "#{options[:label] || attr.to_s.humanize} #{errors}.",
        :class => 'field_error'
    end
  end
end

