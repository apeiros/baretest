BareTest.suite "Advanced I - Dependencies via :provides and :depends_on", :use => :basic_verifications do
  suite "Dependencies" do
    suite "Existing dependency" do
      suite "A", :provides => :a do
        exercise "The given exercise" do
        end

        verify "will succeed, due to that, :a will be provided" do
          true
        end
      end

      suite "B, depending on A", :depends_on => :a do
        exercise "The given exercise" do
        end

        verify "will succeed, because the dependency ':a' is provided" do
          true
        end
      end
    end

    suite "Missing dependency" do
      suite "C", :provides => :c do
        exercise "The given exercise" do
        end

        verify "will fail, due to that, :c will NOT be provided" do
          fail 'Intentional failure'
        end
      end

      suite "D, depending on C", :depends_on => :c do
        exercise "The given exercise" do
        end

        verify "will be skipped, because the dependency ':c' is not provided" do
          fail "This exercise should have been skipped."
        end
      end
    end
  end
end
