# pretend the lib 'baretest/demo/06_advanced_requires' was already loaded
$LOADED_FEATURES << 'baretest/demo/06_advanced_requires'


# You can baretest tell that a suite depends on an external lib using the
# :requires option, it accepts either a String or an Array of strings.
BareTest.suite "Advanced III - Requires option" do

  # Baretest will load all libraries mentioned in :requires via a standard
  # Kernel.require upon suite definition
  suite "Depends on an existing lib", :requires => 'baretest/demo/06_advanced_requires' do
    exercise "Do nothing" do
    end

    verify "and get a success because library-dependency is met" do
      true
    end
  end

  suite "Depends on a missing lib", :requires => 'baretest/demo/06_advanced_requires_missing' do
    exercise "Do nothing" do
    end

    verify "and get a failure because library-dependency is NOT met" do
      true
    end
  end
end
