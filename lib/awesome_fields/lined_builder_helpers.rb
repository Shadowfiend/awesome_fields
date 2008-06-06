module AwesomeFields
  # Helpers for the +LinedBuilder+ class for inclusing directly in
  # +ApplicationHelper+. Allows magic like +lined_form_for+ and
  # +lined_fields_for+.
  module LinedBuilderHelpers
    # Behaves exactly the same as +form_for+, but ensures that the resulting
    # builder object will be a +LinedBuilder+.
    def lined_form_for(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts[:builder] = LinedBuilder
      args << opts
      form_for(*args) { |f| yield f }
    end

    # Behaves exactly the same as +fields_for+ but ensures that the resulting
    # builder object will be a +LinedBuilder+.
    def lined_fields_for(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts[:builder] = LinedBuilder
      args << opts
      fields_for(*args) { |f| yield f }
    end
  end
end
