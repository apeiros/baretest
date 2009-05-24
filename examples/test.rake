# This rake task expects to be in PROJECT_DIR/tasks/test.rake
# It assumes that the tests are in PROJECT_DIR/test/**/*.rb
# This is relevant as it calculates the paths accordingly.
# Additionally it will add PROJECT_DIR/lib - if present - to $LOAD_PATH.

desc "Run testsuite. Set FORMAT env variable to change the formatter used."
task :test do
	begin
		require 'test'
	rescue LoadError => e
		puts "Could not run tests: #{e}"
	else
		# Prepare paths
		rake_file = File.expand_path(__FILE__)
		test_dir  = File.expand_path("#{rake_file}/../../test")
		lib_dir   = File.expand_path("#{rake_file}/../../lib")

		# Verify that the test directory exists
		raise "Could not determine test directory, please adapt this rake task to " \
					"your directory structure first." unless File.directory?(test_dir)

		# Add PROJECT_DIR/lib to $LOAD_PATH if the dir exists
		if File.directory?(lib_dir) && !$LOAD_PATH.include?(lib_dir) then
			$LOAD_PATH.unshift(lib_dir)
			puts "Added '#{lib_dir}' to $LOAD_PATH" if $VERBOSE
		end

		# Load all test definitions
		Dir.glob(File.expand_path("#{test_dir}/**/*.rb")) { |path|
			require path
		}

		# Run all tests
		formatter = ENV["FORMAT"] || 'cli'
		Test.run.run(formatter)
	end
end
