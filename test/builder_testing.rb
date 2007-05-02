# Contains methods for testing +FormBuilder+ objects.
module BuilderTesting
  # Renders some code as if it were running in a view within a +form_for+ block
  # with a `builder' FormBuilder. Returns the resulting output. The FormBuilder is
  # instantiated for the given model object. No methods are called on this object,
  # so it can be a mock object that responds only to the methods you need it to.
  #
  # The object name passed to the +form_for+ block is `model'.
  #
  # Example:
  #  in_builder_for(MyModel.new) { "<%= builder.text_filed :attribute %>" } =>
  #  <form action="/test/test_action" method="post">
  #    <input id="model_attribute" name="model[attribute]" size="30" type="text" value="Test String" />
  #  </form>
  def in_builder_for(model, &block)
    ctrl = TestController.new
    TestController.class_eval do
      define_method(:test_action) do
        vars = yield

        if vars.is_a?(Hash)
          code = vars.delete :code
        else
          code = vars
          vars = {}
        end

        render :inline =>
          "<% form_for(:model, model) do |builder| -%>
            #{code}
          <% end %>", :locals => vars.merge({ :model => model })
      end
    end

    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @controller = ctrl
    get(:test_action)

    @response.body
  end

  # Renders code as with +in_builder_for+, but takes a hash of locals to have
  # within the builder. Equivalent to calling +in_builder_for+ and returning,
  # from the block, both a hash and a value.
  def in_builder_with_locals_for(model, locals = {}, &block)
    in_builder_for(model) do
      locals.reverse_merge(:code => yield)
    end
  end

  def page; self; end
end

