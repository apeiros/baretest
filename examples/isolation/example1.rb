class Foo
  def foo
    "foo"
  end
end

BareTest.suite "Isolation example" do
  assert "Do some silly stuff" do
    ::Foo.class_eval do def foo; "bar"; end; end
    equal "bar", ::Foo.new.foo
  end

  assert "Unaffected by prior silly stuff" do
    equal "foo", ::Foo.new.foo
  end
end