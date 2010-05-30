BareTest.new_component :tabular_data do
  BareTest.require 'baretest/component/tabular_data'
  BareTest.require 'baretest/phase/setuptabulardata'

  BareTest::SetupConstructor.class_eval do
    def tabular_data(string, &code)
      if @existing then
        @existing.add_variant(string, &code)
      else
        @suite.add_setup ::BareTest::Phase::SetupTabularData.new(@id, string, &code)
      end
    end
  end
end
