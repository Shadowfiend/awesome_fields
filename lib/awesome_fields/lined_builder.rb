module AwesomeFields
  # This class presents a builder that provides a per-field block-level element.
  # The class also takes care of labeling fields, as well as adding errors to
  # the fields when needed.
  #
  # == Label
  #
  # Each field method that has been redefined in this builder uses the field
  # name as a label by default (converted to the label text by #humanize-ing it.
  # It also takes an optional <tt>:label</tt> parameter that specifies label
  # text other than the humanized field name. Whatever the field, it is placed
  # in label tag that is linked to the generated field when possible.
  #
  # In addition, the <tt>:no_label</tt> option may be passed to omit the label
  # when generating the field.
  #
  # == Wrapping div
  #
  # When producing a field, the field is wrapped with a div whose CSS class is
  # +form_line+. If the field has errors, that class is instead
  # +form_line_with_errors+. This div is, obviously, a block-level element by
  # default, but can be floated or what have you if needed.
  #
  # == Errors
  #
  # As mentioned above, if the field has an error, the wrapping div is given the
  # +form_line_with_errors+ CSS class instead of the regular +form_line+ class.
  # Additionally, the error text is placed within the containing +form_line+ div
  # within its own div, whose class is +field_error+.
  #
  # The error message is assembled in parts: first, the field is checked for
  # errors. If it has more than one error, these are turned into a sentence via
  # a call to +to_sentence+. Then, the error text has the label prepended to it.
  # By default, the label is the field name, so the error text will have the
  # field name, humanized, prepended to it. Finally, a period (.) is appended to
  # the end. This is the error message that is displayed.
  #
  # == Results
  #
  # The resulting structure of a field with errors is:
  #
  #  <div class="form_line_with_errors">
  #    <div class="field_error">Field should not be blank.</div>
  #
  #    <label for="model_field">Field:</label>
  #    <input type="text" id="model_field" name="model[field]" value="" />
  #  </div>
  #
  # While one without errors has structure:
  #
  #  <div class="form_line">
  #    <label for="model_field">Field:</label>
  #    <input type="text" id="model_field" name="model[field]" value="" />
  #  </div>
  #
  # And one with no errors and no label has structure:
  #
  #  <div class="form_line">
  #    <input type="text" id="model_field" name="model[field]" value="" />
  #  </div>
  #
  # == <tt>:long</tt> option
  #
  # All helpers support a <tt>:long</tt> option in case the field is meant to
  # contain `long' content. For most fields, all this means is that the label
  # for the field will receive the CSS class +long+ if that option is set to
  # true.
  #
  # Currently the only exception to this is +text_area+, which makes use of the
  # <tt>:long</tt> option to modify the default rows and columns of the text
  # area. If the text area is not `long', then it has 10 rows and 30 columns. If
  # it is `long', then it has 20 rows and 70 columns.
  #
  # == Submit button
  #
  # This builder also adds a method +submit_button+ (which is aliased to the
  # default +submit+) that wraps the submit button in a div of class
  # +form_buttons+.
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

    # Takes the additional option <tt>:long</tt> which, if set to true, will, in
    # addition to setting the label's CSS class to +long+ (which happens for all
    # other fields to), change the default rows and columns to 20x70 (instead of
    # the non-long 10x30 defaults).
    def text_area(label, options = {})
      if options[:long]
        options.reverse_merge!({ :rows => 20, :cols => 70 })
      else
        options.reverse_merge!({ :rows => 10, :cols => 30 })
      end

      labeled_field(label, options) { super label, options }
    end

    # Produces a date select. The date select has a default order of month, day,
    # year. Aliased as +date_field+ for uniformity with other field invocations
    # and for good interoperability with the +AwesomeFields+ field helpers.
    def date_select(label, options = {})
      options.reverse_merge!({ :order => [ :month, :day, :year ] })

      labeled_field(label, options) { super label, options }
    end
    alias_method :date_field, :date_select

    # Produces a select box. If the html_options contains the <tt>:multiple</tt>
    # option and it is set to true, then the default size is set to 5.
    def select(label, choices, options = {}, html_options = {})
      err = error_on label, options

      html_options.reverse_merge!({ :size => 5 }) unless html_options[:multiple].nil?

      @template.content_tag( 'div',
        (err ? err : '') + label_tag( label, options ) +
          super,
        :class => err ? 'form_line_with_errors' : 'form_line' )
    end

    # Produces a submit button wrapped in a div of class +form_buttons+. The
    # label is turned into a string and humanized, so it can be a string,
    # potentially underscored.
    #
    # Aliased to +submit+, which is the default Rails name for this method.
    def submit_button(label = 'submit', options = {})
      @template.content_tag 'div',
        @template.submit_tag(label.to_s.humanize),
        :class => 'form_buttons'
    end
    alias_method :submit, :submit_button

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
