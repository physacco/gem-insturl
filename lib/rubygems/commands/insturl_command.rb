require 'rubygems/commands/build_command'
require 'rubygems/commands/install_command'

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
  * gem insturl http://foo.com/bar.gem
  * gem insturl http://foo.com/bar.tar.gz
  * gem insturl --git http://foo.com/bar.git

Download:
  If --git is specified, the URL is treated as a repository and cloned
  with `git`; otherwise it is treated as a package file and downloaded
  with `wget`. You must have git or wget installed in PATH.

Installation:
  If --git is omitted and the URL ends with .gem, it is installed with
  `gem install` directly after download.

  If the URL is a repository or .zip/.tar.gz package, it must have a
  valid *gemspec* file in top level directory. A gem is built from the
  gemspec file and then installed.
EOF
  end
  
  def arguments
    <<EOF
URL        location of the package or git repository
           If --git not set, URL should end with .gem/.zip/.tar.gz
EOF
  end
  
  def usage
    "#{program_name} URL"
  end
  
  def execute
    require 'tempfile'
    require 'fileutils'

    url = options[:args].first
    raise Gem::Exception.new("URL is missing") if url.nil?

    # check package format
    unless options[:git]
      pkgname = File.basename url
      unless pkgname.end_with? ".gem" or
             pkgname.end_with? ".zip" or
             pkgname.end_with? ".tar.gz"
        raise Gem::Exception.new("unsupported package format")
      end
    end

    dir = Dir.mktmpdir
    begin
      if options[:git]
        return unless system("git clone #{url} #{dir}")

        Dir.chdir dir do
          install_gemspec
        end
      else
        Dir.chdir dir do
          # download
          return unless system("wget -O #{pkgname} #{url}")

          if pkgname.end_with? ".gem"
            install_gem pkgname
          else
            # extract
            if pkgname.end_with? ".zip"
              return unless system("unzip #{pkgname}")
            else
              return unless system("tar xzf #{pkgname}")
            end

            # get dirname (FIXME)
            dir2 = File.basename pkgname, ".zip"

            Dir.chdir dir2 do
              install_gemspec
            end
          end
        end
      end
    ensure
      FileUtils.rm_rf dir
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

    # prevent overriding
    unless options[:override]
      find_gem_versions(name).each do |vsn|
        if vsn == version
          err = "#{name} #{version} has already been installed"
          raise Gem::Exception.new(err)
        end
      end
    end

    # build and install
    build_gem gemspec
    install_gem "#{name}-#{version}.gem"
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
    Gem::Commands::BuildCommand.new.invoke gemspec_file
  end

  # Install a gem.
  # e.g. gem-insturl-0.1.0.gem
  def install_gem(gem_file)
    Gem::Commands::InstallCommand.new.invoke gem_file
  end
  
end # class Gem::Commands::InsturlCommand
