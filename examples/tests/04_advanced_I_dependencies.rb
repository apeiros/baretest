BareTest.suite do
  suite "Dependencies" do
    suite "Existing dependency" do
      suite "A", :provides => :a do
        assert "This assertion will succeed, due to that, :a will be provided" do
          true
        end
      end

      suite "B, depending on A", :depends_on => :a do
        assert "This assertion will succeed, because the dependency ':a' is provided" do
          true
        end
      end
    end

    suite "Missing dependency" do
      suite "C", :provides => :c do
        assert "This assertion will fail, due to that, :c will NOT be provided" do
          failure 'Intentional failure'
        end
      end

      suite "D, depending on C", :depends_on => :c do
        assert "This assertion will be skipped, because the dependency ':c' is not provided" do
          true
        end
      end
    end
  end
end
