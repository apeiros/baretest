class Foo
  def foo
    "foo"
  end
end

BareTest.suite "Isolation example" do
  exercise "Redefine Foo#foo" do
    ::Foo.class_eval do def foo; "bar"; end; end
  end
  verify "changes take effect" do
    equal "bar", ::Foo.new.foo
  end

  exercise "Don't do anything" do
    # for real, we don't do anything here
  end
  assert "Foo#foo is not redefined" do
    equal "foo", ::Foo.new.foo
  end
end