#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'stringio'
require 'ostruct'
require 'silverplatter/project/version'
begin
  require 'rbconfig' # used to determine the correct gem executable
rescue LoadError; end


# The module BoneSplitter offers various helpful methods for rake tasks.
#
module BoneSplitter
  def self.find_executable(*names)
    path = ENV["PATH"].split(File::PATH_SEPARATOR)
    names.each { |name|
      next unless name
      found = path.map { |path| File.join(path, name) }.find { |e| File.executable?(e) }
      return found if found
    }
    nil
  end

  @libs = {}

  # we assume that the gem executable name follows the same pattern as the ruby executable name,
  # e.g. if you run ruby1.9, you want gem1.9, if you run jruby, you want jgem, macruby is macgem
  # etc.
  ruby_install_name = defined?(Config::CONFIG["RUBY_INSTALL_NAME"]) && Config::CONFIG["RUBY_INSTALL_NAME"]
  guessed_gem_name  = ruby_install_name && ruby_install_name.sub(/ruby/,'gem')

  @bin = OpenStruct.new(
    :diff => find_executable('diff', 'gdiff', 'diff.exe'),
    :sudo => find_executable('sudo'),
    :rcov => find_executable('rcov', 'rcov.bat'),
    :rdoc => find_executable('rdoc', 'rdoc.bat'),
    :gem  => find_executable(ENV["GEM"], guessed_gem_name, 'gem', 'gem1.9', 'gem1.8', 'gem.bat'),
    :git  => find_executable('git')
  )

  class <<BoneSplitter
    attr_accessor :libs, :bin
  end

  private
  def optional_task(name, depends_on_constant)
    # puts "#{name} requires #{depends_on_constant}: #{!!deep_const(depends_on_constant)}"
    deep_const(depends_on_constant)
    yield
  rescue NameError # constant does not exist
    task name do
      "You're missing a dependency to run this task (#{depends_on_constant})"
    end
  end

  def deep_const(name)
    name.split(/::/).inject(Object) { |nesting, name|
      raise NameError, "uninitialized constant #{nesting}::#{name}" unless nesting.const_defined?(name)
      nesting.const_get(name)
    }
  end

  def version_proc(constant)
    proc {
      version = begin
        deep_const(constant)
      rescue NameError
        file    = constant.gsub(/::/, '/').downcase
        require(file)
        deep_const(constant)
      end
      version && version.to_s
    }
  end

  def quietly
    verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = verbose
  end

  def silenced
    a,b     = $stderr, $stdout
    $stderr = StringIO.new
    $stdout = StringIO.new
    yield
  ensure
    $stderr, $stdout = a,b
  end

  # same as lib? but aborts if a dependency isn't met
  def dependency(names, version=nil, warn_message=nil)
    abort unless lib?(names, version, warn_message)
  end
  alias dependencies dependency

  def lib?(names, version=nil, warn_message=nil)
    if Hash === names then
      warn_message = version
    else
      names        = Array(names).map { |name| [name, version] }
    end

    names.map { |name, version|
      next true if BoneSplitter.libs[name] # already been required earlier
      begin
        gem name, version if version
        silenced do # squelch warnings some 'nice' libs generate
          require name
        end
        BoneSplitter.libs[name] = true
        true
      rescue LoadError
        warn(warn_message % name) if warn_message
        false
      end
    }.all? # map first so we get all messages at once
  end

  # Add a lib as present. Use this to fake existence of a lib if you have
  # an in-place substitute for it, like e.g. RDiscount for Markdown.
  def has_lib!(*names)
    names.each { |name|
      BoneSplitter.libs[name] = true
    }
  end

  def manifest(mani=Project.meta.manifest)
    if File.exist?(mani) then
      File.read(mani).split(/\n/)
    else
      []
    end
  end

  def bin
    BoneSplitter.bin
  end

  def manifest_candidates
    cands = Dir['**/*']
    if Project.manifest.ignore then
      Project.manifest.ignore.map { |glob| cands -= Dir[glob] }
    end
    cands - Dir['**/*/'].map { |e| e.chop }
  end

  def has_version?(having_version, minimal_version, maximal_version=nil)
    a = Version(having_version)
    b = Version(minimal_version)
    if maximal_version then
      a.between?(b,Version(maximal_version))
    else
      a >= b
    end
  end

  # requires that 'readme' is a file in markdown format and that Markdown exists
  def extract_summary(file=Project.meta.readme)
    return nil unless File.readable?(file)
    return nil unless lib?('nokogiri', nil, "Requires %s to extract the summary")
    html = case File.extname(file)
      when '.rdoc'
        return nil unless lib?('rdoc/markup/to_html', nil, "Requires %s to extract the summary")
        RDoc::Markup::ToHtml.new.convert(File.read('README.rdoc'))
      when '.markdown'
        return nil unless lib?('markdown', nil, "Requires %s to extract the summary")
        Markdown.new(File.read(file)).to_html
    end
    sibling = (Nokogiri.HTML(html)/"h2[text()=Summary]").first.next_sibling
    sibling = sibling.next_sibling until sibling.node_name == 'p'
    sibling.inner_text.strip
  rescue => e
    warn "Failed extracting the summary: #{e}"
    nil
  end

  # requires that 'readme' is a file in markdown format and that Markdown exists
  def extract_description(file=Project.meta.readme)
    return nil unless File.readable?(file)
    return nil unless lib?('nokogiri', nil, "Requires %s to extract the summary")
    html = case File.extname(file)
      when '.rdoc'
        return nil unless lib?('rdoc/markup/to_html', nil, "Requires %s to extract the summary")
        RDoc::Markup::ToHtml.new.convert(File.read('README.rdoc'))
      when '.markdown'
        return nil unless lib?('markdown', nil, "Requires %s to extract the summary")
        Markdown.new(File.read(file)).to_html
    end
    sibling = (Nokogiri.HTML(html)/"h2[text()=Description]").first.next_sibling
    sibling = sibling.next_sibling until sibling.node_name == 'p'
    sibling.inner_text.strip
  rescue => e
    warn "Failed extracting the description: #{e}"
    nil
  end

  # Create a Gem::Specification from Project.gem data.
  def gem_spec(from)
    Gem::Specification.new do |s|
      s.name                  = from.name
      s.version               = from.version
      s.summary               = from.summary
      s.authors               = from.authors
      s.email                 = from.email
      s.homepage              = from.homepage
      s.rubyforge_project     = from.rubyforge_project
      s.description           = from.description
      s.required_ruby_version = from.required_ruby_version if from.required_ruby_version

      from.dependencies.each do |dep|
        s.add_dependency(*dep)
      end if from.dependencies

      s.files            = from.files
      s.executables      = from.executables.map {|fn| File.basename(fn)}
      s.extensions       = from.extensions

      s.bindir           = from.bin_dir
      s.require_paths    = from.require_paths if from.require_paths

      s.rdoc_options     = from.rdoc_options
      s.extra_rdoc_files = from.extra_rdoc_files
      s.has_rdoc         = from.has_rdoc

      if from.test_file then
        s.test_file  = from.test_file
      elsif from.test_files
        s.test_files = from.test_files
      end

      # Do any extra stuff the user wants
      from.extras.each do |msg, val|
        case val
          when Proc
            val.call(s.send(msg))
          else
            s.send "#{msg}=", val
        end
      end
    end # Gem::Specification.new
  end

  # Returns a good name for the gem-file using the spec and the package-name.
  def gem_file(spec, package_name)
    if spec.platform == Gem::Platform::RUBY then
      "#{package_name}.gem"
    else
      "#{package_name}-#{spec.platform}.gem"
    end
  end
end # BoneSplitter
