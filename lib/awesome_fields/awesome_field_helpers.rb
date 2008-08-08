module AwesomeFields
  # Contains the helpers used for the awesome_fields plugin. The most relevant
  # method is the +field+ method, which provides the meat of the functionality
    # in awesome_fields. Other helpers are present to aid the field method.
  module AwesomeFieldHelpers
    # Generates a field for the specified attribute. Uses first introspection
    # (gets the method value and asks it for its class) and then the database (if
    # the method returns nil) to determine which field helper to use. Note that
    # there are some limitations to this
    # method; namely:
    # * String fields are made via text_field rather than text_area (you can
    #   pass :long => true to always get a text_area);
    # * Since Rails usually typecasts Date and DateTime fields to Time objects,
    #   there's an extra level of indirection when determining what field type
    #   to generate for these three types, since the database type is always
    #   checked.
    # * Certain fields, like country_select and time_zone_select, cannot currently
    #   be introspected.
    #
    # Support for +collection_field+ is somewhat automated. If the specified
    # method returns a collection (responds to +collect+), +collection_field+
    # is used.
    #
    # Need to define a way to handle new types? This method just calls a method
    # that corresponds to the name of your class, underscored, followed by
    # +_field+ (a method value of String, for example, yields a call to
    # string_field). So just alias a normal field helper (whichever one you
    # prefer) to the appropriate name (to add support for the Magic class to be
    # handled with a text_field, for example, use <tt>alias :magic_field
    # :text_field</tt>).
    def field(method, *args)
      method_value = @object.send(method)

      # Try looking in the DB if the method returned nil; otherwise, use the
      # return value's class to determine the field.
      if method_value.nil?
        type_method = type_method_from_database(method)
      else
        type_method = method_value.class.name.underscore + '_field'
      end

      # Default to a string field if all else fails.
      type_method = 'string_field' if type_method.nil?

      # Return a collection field if we have a value that responds to collect
      # and isn't a String (since Strings aren't quite Arrays).
      return collection_field(method,*args) \
        if method_value.respond_to?(:collect) and ! method_value.is_a?(String)

      self.send type_method, method, *args
    end

    alias :field_for :field

    def string_field(method, *args)
      opts, html_opts = html_and_other_options_from(args)
      if opts[:long]
        self.text_area method, *args
      else
        self.text_field method, *args
      end
    end

    # Generates a field for collections of objects. Does a lot more guessing and
    # provides a lot more convention-over-configuration goodness than the
    # default +collection_select+ method does. Note that it uses +select+
    # instead of +collection_select+ in order to provide appropriate default
    # selection of multiple elements.
    #
    # The simplest way to call this method is just with a method name:
    #  f.collection_field(:my_field)
    # At this point, you give yourself entirely over to the guessing that
    # +awesome_fields+ does:
    # * The value of the options will be that of the +to_param+ method called
    #   on each element in the collection.
    # * The text for those options will be that of the +name+ method or the
    #   +to_s+ method, depending on whether the +name+ method exists or not.
    # * The full list of possible options will be derived by calling
    #   <tt>find(:all)</tt> on the class of the first object of the collection.
    #
    # This is based on a few larger assumptions:
    # * The collection is homogeneous (i.e., all objects are of the same class).
    # * We are dealing with a collection of +ActiveRecord+ objects.
    #
    # If any of the above assumptions are false, you will have to do a little
    # more work, namely, passing options. Here is a list of the relevant
    # options:
    # <tt>:text_method</tt>::  The method used to specify the text of the options.
    # <tt>:value_method</tt>:: The method used to specify the value of the
    #                          options (which will be the value returned to the
    #                          application).
    # <tt>:collection</tt>:: A collection to use instead of calling
    #                        <tt>find(:all)</tt> on the class of the first
    #                        element of the selected values.
    #
    # Other options are passed on to the +select+ method.
    def collection_field(method, opts = {}, html_options = {})
      selected = @object.send(method)
      selected = [ selected ] if ! selected.respond_to?(:first)
      reference_object = opts[:collection] ? opts[:collection].first \
                                           : selected.first

      value_meth = opts[:value_method] || :to_param
      text_meth =  opts[:text_method]  || text_method_for(reference_object)
      collection = opts[:collection]   || reference_object.class.find(:all)

      all_values = collection.collect do |item|
        [ item.send(text_meth), item.send(value_meth) ]
      end
      selected_values = selected.collect { |item| item.send(value_meth) }

      self.select(method, all_values, opts.merge(:selected => selected_values),
                  html_options)
    end

    alias :collection_field_for :collection_field

    # Determines whether to generate a time, datetime, or date select depending on
    # the _database_ type of the attribute. Defaults to a time select if the
    # attribute is a virtual attribute (i.e., it has no associated database
    # column).
    def time_field(method, *args)
      db_type = type_from_database(method)

      # Note that if the database type is string or text, we still use a
      # time_select, as we're assuming it is then a serialized object.
      unless db_type.nil? or db_type =~ /^(?:string|text)$/
        self.send "#{db_type}_select", method, *args
      else
        self.time_select method, *args
      end
    end

    # Sets up aliases for use by +field+.
    def self.included(mod)
      mod.class_eval do
        alias :integer_field   :string_field
        alias :fixnum_field    :string_field
        alias :nil_class_field :string_field
        alias :decimal_field   :string_field
        alias :date_field      :date_select
        alias :datetime_field  :datetime_select
      end
    end

    protected
      # Returns a type method (the name of the method that will generate the
      # appropriate field) based on the database type of the attribute.
      def type_method_from_database(attribute)
        type = type_from_database(attribute)

        unless type.nil?
          "#{type}_field"
        else
          nil
        end
      end

      # Returns the type of the attribute as specified by the database (as a
      # lowercase string, not a symbol).
      def type_from_database(attribute)
        col = @object.column_for_attribute(attribute)

        unless col.nil?
          col.type.to_s.downcase
        else
          nil
        end
      end

      # Returns a method to obtain display text for a collection of objects of
      # the same type as the specified one. If the object responds to +name+,
      # that will be used; otherwise, +to_s+ will be used.
      def text_method_for(obj)
        if obj.respond_to?(:name)
          :name
        else
          :to_s
        end
      end

      # Resolves +html_options+ and regular +options+ hashes from a list of
      # extra arguments.
      #
      # Returns options, then html_options, as a pair of return values.
      def html_and_other_options_from(args)
        opts, html_opts = {}, {}

        opts = args.pop if args.last.is_a?(Hash)
        html_opts = opts and opts = args.pop if args.last.is_a?(Hash)

        return opts, html_opts
      end
  end
end
