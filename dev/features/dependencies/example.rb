require 'parser'

BareTest.suite 'Syntax' do
  suite 'primitives' do
    suite "nil" do
      setup do
        syntax  = Parser::Syntax.new %w[syntax/primitives]
        @parser = Parser.new(syntax)
      end

      assert "Parses" :id => :parses do
        @parser.parse("nil") do nil_token end
      end

      requiring :parses do
        setup do
          @parser.parse("nil") do nil_token end
        end

        assert "Is clean" do
          @parser.clean?
        end

        assert "Is at end_of_buffer" do
          @parser.end_of_buffer?
        end
  
        assert "Is a NilToken" do
          equal :nil_token, @parser.root.children.first.class.node_id
        end
      end
    end
  end
end