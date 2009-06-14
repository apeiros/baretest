#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



Test.define "Test with test/debug", :requires => 'test/debug' do
  suite "Assertion with test/debug", :requires => 'test/debug' do
    suite "#to_s" do
      assert "Assertion should have a to_s which contains the classname and the description" do
        description  = "the description"
        assertion    = Test::Assertion.new(nil, description)
        print_string = assertion.to_s

        print_string.include?(assertion.class.name) &&
        print_string.include?(description)
      end
    end

    suite "#inspect" do
      assert "Assertion should have an inspect which contains the classname, the shifted object-id in zero-padded hex, the suite's inspect and the description's inspect" do
        suite          = Test::Suite.new
        description    = "the description"
        assertion      = Test::Assertion.new(suite, description)
        def suite.inspect; "<inspect of suite>"; end

        inspect_string = assertion.inspect

        inspect_string.include?(assertion.class.name) &&
        inspect_string.include?("%08x" % (assertion.object_id >> 1)) &&
        inspect_string.include?(suite.inspect) &&
        inspect_string.include?(description.inspect)
      end
    end
  end

  suite "Suite with test/debug", :requires => 'test/debug' do
    suite "#to_s" do
      assert "Suite should have a to_s which contains the classname and the description" do
        description  = "the description"
        suite        = Test::Suite.new(description)
        print_string = suite.to_s

        print_string.include?(suite.class.name) &&
        print_string.include?(description)
      end
    end

    suite "#inspect" do
      assert "Suite should have an inspect which contains the classname, the shifted object-id in zero-padded hex and the description's inspect" do
        description    = "the description"
        suite          = Test::Suite.new(description)
        inspect_string = suite.inspect

        inspect_string.include?(suite.class.name) &&
        inspect_string.include?("%08x" % (suite.object_id >> 1)) &&
        inspect_string.include?(description.inspect)
      end
    end
  end
end
