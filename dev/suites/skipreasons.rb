BareTest.suite do
  suite "Skipped due manual skipping, no reason", :skip => true do
    assert "Tell him why I was skipped" do true end
    suite "Nested" do
      assert "Tell him why I was skipped" do true end
    end
  end

  suite "Skipped due manual skipping, with reason", :skip => 'some oddly good reason' do
    assert "Tell him why I was skipped" do true end
    suite "Nested" do
      assert "Tell him why I was skipped" do true end
    end
  end

  suite "Skipped due to require", :requires => 'inexisting123' do
    assert "Tell him why I was skipped" do true end
    suite "Nested" do
      assert "Tell him why I was skipped" do true end
    end
  end

  suite "Skipped due to dependency", :depends_on => :inavailable do
    assert "Tell him why I was skipped" do true end
    suite "Nested" do
      assert "Tell him why I was skipped" do true end
    end
  end

  suite "Skipped due to missing component", :use => :inavailable do
    assert "Tell him why I was skipped" do true end
    suite "Nested" do
      assert "Tell him why I was skipped" do true end
    end
  end
end
