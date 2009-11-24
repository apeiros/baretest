class XSuite
  def setup(component=nil, multiplexed=nil, &block)
    if block then
      @setup[component] ||= []
      case multiplexed
        when String
          @setup[component] << BareTest::Setup.new(multiplexed, nil, block)
        when Array
          multiplexed.each do |substitute|
            @setup[component] << BareTest::Setup.new(substitute.to_s, substitute, block)
          end
        when Hash
          multiplexed.each do |substitute, value|
            @setup[component] << BareTest::Setup.new(substitute, value, block)
          end
      end
    else
      @setup
    end
  end
end

class Run
  def run_suite(suite)
    suite.assertions.each do |test|
      run_test_variants(test)
    end
    suite.suites.each do |(description, suite)|
      run_suite(suite)
    end
    @count[:suite] += 1
  end

  def run_test_variants(test)
    test.suite.each_component_variant do |setups|
      run_test(test, setups)
    end
  end

  def run_test(assertion, setup)
    rv = assertion.execute
    @count[:test]            += 1
    @count[assertion.status] += 1
    rv
  end
end

class Suite
  def initialize
    @components = []
    @setup      = {nil => []}
  end

  def setup(component, variant)
    @components << component unless @setup.has_key?(component)
    @setup[component] ||= []
    @setup[component] << variant
  end

  def each_component_variant
    base = @setup[nil]

    if @components.empty?
      yield(base) unless base.empty?
    else
      setup_in_order = @setup.values_at(*@components)
      maximums       = setup_in_order.map { |i| i.size }
      iterations     = maximums.inject { |r,f| r*f } || 0

      iterations.times do |i|
        process = maximums.map { |e| i,e=i.divmod(e); e }
        yield base+setup_in_order.zip(process).map { |variants, current|
          variants[current]
        }
      end
    end

    self
  end
end

def print_variants(s, d)
  puts d
  i = 0
  s.each_component_variant do |setups|
    puts "  #{i+=1}:"
    setups.each do |v|
      print "    ",v,"\n"
    end
  end
  puts
end

s = Suite.new
print_variants s, "Empty: "

s.setup nil, "standard 1"
print_variants s, "Single: "

s.setup :a, "a 1"
print_variants s, "1x a, 1x Normal: "

s.setup :a, "a 2"
print_variants s, "2x a, 1x Normal: "

s.setup nil, "standard 2"
print_variants s, "2x a, 2x Normal: "

s.setup :b, "b 1"
print_variants s, "2x a, 1x b, 2x Normal: "

s.setup :b, "b 2"
print_variants s, "2x a, 2x b, 2x Normal: "

