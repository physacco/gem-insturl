class Gem::Commands::InsturlCommand < Gem::Command

  def initialize
    super "insturl", "Install a gem from a URL"

    add_option("--git", "use `git clone' to fetch the URL") do |val, opt|
      options[:git] = true
    end

    add_option("--override", "install even if already exists") do |val, opt|
      options[:override] = true
    end
  end

  def description
    <<EOF
The insturl command installs a gem from a URL.

Examples:
  * gem insturl http://.../foo.git
  * gem insturl http://.../foo.gem
  * gem insturl http://.../foo.tar.gz

Download:
  If --git is specified or the URL ends with .git, it is treated as a
  git repository and cloned with `git`; otherwise it is treated as a
  package file and downloaded with `wget`. You must have git or wget
  installed in PATH.

Installation:
  If --git is omitted and the URL ends with .gem, it is installed with
  `gem install` directly after download.

  If the URL is a repository or a .zip/.tar.gz package, it must have a
  valid *gemspec* file in top level directory. A gem is built from the
  gemspec file and then installed.
EOF
  end
  
  def arguments
    "URL        location of the package or git repository"
  end
  
  def usage
    "#{program_name} URL"
  end
  
  def execute
    url = options[:args].first
    raise Gem::Exception.new("URL is missing") if url.nil?

    # check package format
    format = determine_package_format url, options

    require 'tempfile'
    dir = Dir.mktmpdir
    begin
      Dir.chdir dir do
        send "install_from_#{format}", url
      end
    ensure
      require 'fileutils'
      FileUtils.rm_rf dir
    end
  end

  def determine_package_format(url, options={})
    return :git if options[:git]

    name = File.basename url
    if name.end_with? ".git"
      :git
    elsif name.end_with? ".gem"
      :gem
    elsif name.end_with? ".tgz"
      :tgz
    elsif name.end_with? ".tar.gz"
      :tgz
    elsif name.end_with? ".zip"
      :zip
    else
      raise Gem::FormatException, "unsupported package format"
    end
  end

  def install_from_git(url)
    return unless system("git clone #{url}")

    topdir = subdirs_in_cwd.first

    Dir.chdir topdir do
      install_gemspec
    end
  end

  def install_from_gem(url)
    return unless system("wget #{url}")

    pkgname = files_in_cwd.first

    # extract gemspec
    spec = get_gem_spec pkgname
    name, version = spec.name, spec.version
    prevent_overriding(name, version) unless options[:override]

    install_gem pkgname
  end

  def install_from_tgz(url)
    return unless system("wget #{url}")

    pkgname = files_in_cwd.first

    return unless system("tar xzf #{pkgname}")

    topdir = subdirs_in_cwd.first

    Dir.chdir topdir do
      install_gemspec
    end
  end

  def install_from_zip(url)
    return unless system("wget #{url}")

    pkgname = files_in_cwd.first

    return unless system("unzip #{pkgname}")

    topdir = subdirs_in_cwd.first

    Dir.chdir topdir do
      install_gemspec
    end
  end
  
  # install from a gemspec file
  def install_gemspec
    # find gemspec file
    gemspecs = Dir['*.gemspec']
    if gemspecs.size == 0
      raise Gem::Exception.new("gemspec not found")
    elsif gemspecs.size > 1
      raise Gem::Exception.new("multiple gemspecs found")
    end
    gemspec = gemspecs[0]

    # load gemspec file
    spec = eval File.read(gemspec)
    name, version = spec.name, spec.version
    prevent_overriding(name, version) unless options[:override]

    # build and install
    build_gem gemspec
    install_gem "#{name}-#{version}.gem"
  end

  # Abort if the gem has already been installed.
  def prevent_overriding(name, version)
    find_gem_versions(name).each do |vsn|
      if vsn == version
        err = "#{name} #{version} has already been installed"
        raise Gem::Exception.new(err)
      end
    end
  end

  # Find installed versions of the gem.
  # Return a sequence of Gem::Version instances.
  def find_gem_versions(name)
    find_gem_specs(name).map{|spec| spec.version}
  end

  # Find installed versions of the gem.
  # Return a sequence of Gem::Specification instances.
  def find_gem_specs(name)
    if Gem::Specification.respond_to? :find_all_by_name
      Gem::Specification.find_all_by_name name
    elsif Gem.respond_to? :source_index and
      Gem.source_index.respond_to? :find_name
      Gem.source_index.find_name name
    else
      raise Gem::Exception.new("unsupported gem version")
    end
  end

  # Build a gem from a gemspec file.
  # e.g. gem-insturl.gemspec -> gem-insturl-0.1.0.gem
  def build_gem(gemspec_file)
    require 'rubygems/commands/build_command'
    Gem::Commands::BuildCommand.new.invoke gemspec_file
  end

  # Install a gem.
  # e.g. gem-insturl-0.1.0.gem
  def install_gem(gem_file)
    require 'rubygems/commands/install_command'
    Gem::Commands::InstallCommand.new.invoke gem_file
  end

  # Get specification of a gem file.
  # Return a Gem::Specification instance.
  def get_gem_spec(gem_file)
    begin
      require 'rubygems/format'
      Gem::Format.from_file_by_path(gem_file).spec
    rescue LoadError
      require 'rubygems/package'
      Gem::Package.new(gem_file).spec
    end
  end

  # List files in current directory.
  # Return an Array of String.
  def files_in_cwd
    Dir["*"].delete_if{|ent| !File.file?(ent)}
  end

  # List subdirectories in current directory.
  # Return an Array of String.
  def subdirs_in_cwd
    Dir["*"].delete_if{|ent| !File.directory?(ent)}
  end
  
end # class Gem::Commands::InsturlCommand
