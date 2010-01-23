BareTest.suite "Demo" do
  suite "A", :provides => :a do
    assert "truth" do true end
  end
  suite "B, depending on A", :depends_on => :a do
    assert "works, because a is provided" do true end
  end

  suite "C", :provides => :c do
    assert "fails" do false end
  end
  suite "D, depending on C", :depends_on => :c do
    assert "skipped, because c is not provided" do true end
  end
end
