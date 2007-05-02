# A mock ActiveRecord class whose instances will appear to be AR objects but
# never interact with the database.
module ARMocking
  # Instantiates a mock ActiveRecord object with the specified list of
  # attributes returning the specified values.
  def mock_ar_with(attributes = {})
    obj = stub
    obj.stubs(:is_a?).with(ActiveRecord::Base).returns(true)
    obj.stubs(:is_a?).returns(false)
    attributes.each { |method, retval| obj.stubs(method).returns(retval) }

    obj
  end
end

