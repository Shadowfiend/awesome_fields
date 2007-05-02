RAILS_ENV = 'test'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'test/spec'

module Test::Spec; module Rails; end; end

# +ShouldSelect+ and +ShouldNotSelect+ are borrowed from the TechnoWeenie
# test/spec On Rails plugin
# (http://svn.techno-weenie.net/projects/plugins/test_spec_on_rails/).
module Test::Spec::Rails::ShouldSelect
  # Wrapper for +assert_select+. Examples:
  #
  # Test that the previous request has a login form:
  #   page.should.select "form#login"
  #
  # Test that a specific form has a field pre-filled (this is specific test/spec/rails):
  #   page.should.select "form#login" do |form|
  #     form.should.select "input[name=user_nick]", :text => @user.nick
  #   end
  #
  # See the Rails API documentation for assert_select for more information
  def select(selector, equality=true, message=nil, &block)
    @object.assert_select(selector, equality, message, &block)
  end
end

module Test::Spec::Rails::ShouldNotSelect
  include Test::Spec::Rails::ShouldSelect
  def select(selector, message=nil, &block)
    super(selector, false, message, &block)
  end
end

Test::Spec::Should.send(:include, Test::Spec::Rails::ShouldSelect)
Test::Spec::ShouldNot.send(:include, Test::Spec::Rails::ShouldNotSelect)
