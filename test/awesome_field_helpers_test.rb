require File.join(File.dirname(__FILE__), 'test_helper.rb')
require File.join(File.dirname(__FILE__), 'builder_testing')
require File.join(File.dirname(__FILE__), 'ar_mocking')
require 'test_help'
require 'mocha'

# A controller used for testing; contains only one action, dubbed +test_action+,
# which may be rewritten by users of the TestController to specialize its
# behavior. By default, it does nothing except re-throw exceptions.
class TestController < ActionController::Base
  def test_action; end
  def rescue_action(e); raise e; end
end

context "awesome_fields" do
  specify 'should add field method to FormBuilder' do
    fb = ActionView::Helpers::FormBuilder.new(nil,nil,nil,nil,nil)
    proc { fb.method(:field) } .should.not.raise NameError
  end

  context 'helpers' do
    include ActionController::Assertions::SelectorAssertions
    include ActionController::TestProcess
    include BuilderTesting

    specify 'string field should return text input' do
      object = stub(:attribute => "Test String")
      body = in_builder_for object  do
        "<%= builder.field(:attribute) %>"
      end

      body.should.be.not.empty
      page.should.select 'input[type=text]', 1
    end

    specify 'string field with long parameter should return textarea' do
      object = stub(:attribute => "Test String")
      body = in_builder_for object do
        "<%= builder.field(:attribute, :long => true) %>"
      end

      body.should.be.not.empty
      page.should.select 'textarea', 1
      page.should.not.select 'input'
    end

    specify 'time field with time db type should return time select' do
      object = stub(:attribute => Time.now)
      object.expects(:column_for_attribute).with(:attribute) \
        .returns(stub(:type => :time))
      body = in_builder_for object do
        "<%= builder.field(:attribute) %>"
      end

      body.should.be.not.empty
      page.should.select "select#?", /^model_attribute_[4-5]i$/, 2
      page.should.select "select#?", /^model_attribute_[^4-5]i$/, 0
    end

    specify 'time field with no db type should return time select' do
      object = stub(:attribute => Time.now)
      object.expects(:column_for_attribute).with(:attribute) \
        .returns(nil)
      body = in_builder_for object do
        "<%= builder.field(:attribute) %>"
      end

      body.should.be.not.empty
      page.should.select "select#?", /^model_attribute_[4-6]i$/, 2
      page.should.select "select#?", /^model_attribute_[^4-6]i$/, 0
    end

    specify 'time field with seconds should return time select with seconds' do
      object = stub(:attribute => Time.now)
      object.expects(:column_for_attribute).with(:attribute) \
        .returns(stub(:type => :time))
      body = in_builder_for object do
        "<%= builder.field(:attribute, :include_seconds => true) %>"
      end

      body.should.be.not.empty
      page.should.select "select#?", /^model_attribute_[4-6]i$/, 3
      page.should.select "select#?", /^model_attribute_[^4-6]i$/, 0
    end

    specify 'time field with date db type should return date select' do
      object = stub(:attribute => Time.now)
      object.expects(:column_for_attribute).with(:attribute) \
        .returns(stub(:type => :date))
      body = in_builder_for object do
        "<%= builder.field(:attribute) %>"
      end

      body.should.be.not.empty
      page.should.select "select#?", /^model_attribute_[1-3]i$/, 3
      page.should.select "select#?", /^model_attribute_[^1-3]i$/, 0
    end

    specify 'time field with datetime db type should return datetime select' do
      object = stub(:attribute => Time.now)
      object.expects(:column_for_attribute).with(:attribute) \
        .returns(stub(:type => :datetime))
      body = in_builder_for object do
        "<%= builder.field(:attribute) %>"
      end

      body.should.be.not.empty
      page.should.select "select#?", /^model_attribute_[1-6]i$/, 5
      page.should.select "select#?", /^model_attribute_[^1-6]i$/, 0
    end

    specify 'time field with datetime db type and seconds should return ' +
        'datetime select with seconds' do
      object = stub(:attribute => Time.now)
      object.expects(:column_for_attribute).with(:attribute) \
        .returns(stub(:type => :datetime))
      body = in_builder_for object do
        "<%= builder.field(:attribute, :include_seconds => true) %>"
      end

      body.should.be.not.empty
      page.should.select "select#?", /^model_attribute_[1-6]i$/, 6
      page.should.select "select#?", /^model_attribute_[^1-6]i$/, 0
    end

    specify 'integer field should return text input' do
      object = stub(:attribute => 5)
      body = in_builder_for object do
        "<%= builder.field(:attribute) %>"
      end

      body.should.be.not.empty
      page.should.select "input[type=text]", 1
    end

    specify 'nil field with integer db type should return text input' do
      object = stub(:attribute => nil)
      object.expects(:column_for_attribute).with(:attribute) \
        .returns(stub(:type => :integer))
      body = in_builder_for object do
        "<%= builder.field(:attribute) %>"
      end

      body.should.be.not.empty
      page.should.select "input[type=text]", 1
    end

    specify 'nil field with time db type should return time select' do
      object = stub(:attribute => nil)
      object.expects(:column_for_attribute).with(:attribute) \
        .returns(stub(:type => :time)).at_most(2)
      body = in_builder_for object do
        "<%= builder.field(:attribute) %>"
      end

      body.should.be.not.empty
      page.should.select "select#?", /^model_attribute_[4-6]i$/, 2
      page.should.select "select#?", /^model_attribute_[^4-6]i$/, 0
    end
  end

  context 'collection helpers' do
    include ActionController::Assertions::SelectorAssertions
    include ActionController::TestProcess
    include BuilderTesting
    include ARMocking

    # Creates the specified number of related objects with the specified methods
    # (as a has, on each of them). If a block is given, yields the resulting
    # list before returning it.
    #
    # If the %id% value is found in any given method, then that location is
    # replaced with the id of the current object.
    def related_objects_with_methods(num, methods = {})
      related_objects = []
      6.times do |time|
        obj_methods = methods.merge(:id => time)
        methods.each do |meth, retval|
          obj_methods[meth] = retval.gsub(/%id%/, obj_methods[:id].to_s) \
            if retval.respond_to?(:gsub!)
        end
        related_objects << mock_ar_with(obj_methods)
      end

      yield related_objects if block_given?

      related_objects
    end

    # Creates an object and the specified number of related objects, giving the
    # specified methods to each of them. By default, the id for the main object
    # is 0. Also by default, the object is only associated with the first three
    # (or all, if there are less than three) related objects via the
    # +related_objects+ method. If a block is given, yields the resulting object
    # and the resulting full list before returning both (in that order).
    def object_with_related_and_methods(num, methods = {})
      related_objects = related_objects_with_methods(num, methods)
      object = mock_ar_with(methods.merge(:id => 0,
                  :related_objects => related_objects[0..2]))

      yield object, related_objects if block_given?

      return object, related_objects
    end

    # Generates a set of assertions in addition to an assertion that the body
    # should not be empty.
    def with_nonempty_body(&block)
      @response.body.should.be.not.empty
      yield
    end

    specify 'collection field for records with name should produce' +
        ' select with id value and name text' do
      obj, rel = object_with_related_and_methods(6, :name => "Object #%id%")

      body = in_builder_for obj do
        { :related_objects => rel,
          :code => "<%= builder.field(:related_objects, :collection =>
              related_objects) %>" }
      end

      with_nonempty_body do
        page.should.select "select#model_related_objects", 1 do
          page.should.select 'option', :text => /Object #\d/, :count => 6
        end
      end
    end

    specify 'collection field for records without name should produce' +
        ' select with id value and to_s text' do
      obj, rel = object_with_related_and_methods(6, :name => "Object #%id%")

      body = in_builder_for obj do
        { :related_objects => rel,
          :code => "<%= builder.field(:related_objects, :collection =>
              related_objects) %>" }
      end

      with_nonempty_body do
        page.should.select "select#model_related_objects", 1 do
          page.should.select 'option', :text => /Object #\d/, :count => 6
        end
      end
    end

    specify 'collection field with no collection specified should use ' +
        'find(:all)' do
      obj, rel = object_with_related_and_methods(6) do |obj, rel_objs|
        rel_objs.first.class.expects(:find).with(:all) .returns(rel_objs)
      end

      body = in_builder_for obj do
        "<%= builder.field(:related_objects) %>"
      end

      with_nonempty_body do
        page.should.select "select#model_related_objects", 1 do
          page.should.select 'option', 6
        end
      end
    end

    specify 'collection field should use specified text method' do
      obj, rel = object_with_related_and_methods(6, :text => 'Object #%id%')

      body = in_builder_with_locals_for obj, :related_objects => rel do
          "<%= builder.field(:related_objects, :collection =>
              related_objects, :text_method => :text) %>"
      end

      with_nonempty_body do
        page.should.select "select#model_related_objects", 1 do
          page.should.select 'option', :text => /Object #\d/, :count => 6
        end
      end
    end

    specify 'collection field should use specified value method' do
      obj, rel = object_with_related_and_methods(6, :value => '#%id%')

      body = in_builder_with_locals_for obj, :related_objects => rel do
        "<%= builder.field(:related_objects, :collection => related_objects,
            :value_method => :value) %>"
      end

      with_nonempty_body do
        page.should.select "select#model_related_objects", 1 do
          page.should.select 'option[value=?]',  /#\d/, :count => 6
        end
      end
    end

    specify 'collection field should select appropriate objects as default' do
      obj, rel = object_with_related_and_methods(6)

      body = in_builder_with_locals_for obj, :related_objects => rel do
        "<%= builder.field(:related_objects, {:collection => related_objects},
                :multiple => true) %>"
      end

      with_nonempty_body do
        page.should.select "select#model_related_objects[multiple=multiple]", 1 do
          page.should.select "option[selected=?]", /.+/, :count => 3
        end
      end
    end

    specify 'collection field should use object in passed :collection over' +
        ' object in method value for reference object' do
      rel = related_objects_with_methods(6, :name => "Object #%id%")
      obj = Object.new
      obj.expects(:related_objects).returns([]).at_most(3)

      body = in_builder_for obj do
        { :related_objects => rel,
          :code => "<%= builder.field(:related_objects, :collection =>
              related_objects) %>" }
      end

      with_nonempty_body do
        page.should.select "select#model_related_objects", 1 do
          page.should.select 'option', :text => /Object #\d/, :count => 6
        end
      end
    end
  end
end

