class Gem::Commands::InsturlCommand < Gem::Command

  def initialize
    super "insturl", "Install a gem from a URL"

    add_option("--git", "use `git clone' to fetch the URL") do |value, options|
      options[:git] = true
    end

    add_option("--force", "install even if already installed") do |value, options|
      options[:force] = true
    end
  end

  def description
    <<EOF
The insturl command installs a gem from a URL.

Examples:
* gem insturl http://foo.com/bar.gem
* gem insturl http://foo.com/bar.tar.gz
* gem insturl --git http://foo.com/bar.git

If --git is specified, the gem is fetched by `git clone URL`;
otherwise it is downloaded with `wget` (you must have wget in PATH)

If the URL ends with .gem, it is directly installed after download.
If it is a git repository or .zip/.tar.gz package, then it must have
a valid *gemspec* file in top level directory.
EOF
  end
  
  def arguments
    "URL        location of the package or git repository\n" +
    "           If --git not set, URL should end with .gem/.zip/.tar.gz"
  end
  
  def usage
    "#{program_name} URL"
  end
  
  def execute
    require 'tempfile'
    require 'fileutils'

    url = options[:args].first
    raise ArgumentError.new("URL is missing") if url.nil?

    # check package format
    unless options[:git]
      pkgname = File.basename url
      unless pkgname.end_with? ".gem" or
             pkgname.end_with? ".zip" or
             pkgname.end_with? ".tar.gz"
        raise ArgumentError.new("unsupported package format")
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
          # download the package
          return unless system("wget -O #{pkgname} #{url}")

          # install the package
          if pkgname.end_with? ".gem"
            system("gem install #{pkgname}")
          elsif pkgname.end_with? ".zip"
            return unless ok system("unzip #{pkgname}")

            dir2 = File.basename pkgname, ".zip"
            Dir.chdir dir2 do
              install_gemspec
            end
          elsif pkgname.end_with? ".tar.gz"
            return unless system("tar xzf #{pkgname}")

            dir2 = File.basename pkgname, ".tar.gz"
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
      raise ArgumentError.new("gemspec not found")
    elsif gemspecs.size > 1
      raise ArgumentError.new("multiple gemspecs found")
    end
    gemspec = gemspecs[0]

    # check if the same gem has been installed
    specobj = eval File.read(gemspec)
    unless options[:force]
      Gem::Specification.find_all do |spec|
        if spec.name == specobj.name and
           spec.version == specobj.version
           err = "#{spec.name} #{spec.version} has already been installed"
           raise ArgumentError.new(err)
        end
      end
    end

    # build gem
    return unless system("gem build #{gemspec}")

    # install gem
    gem = "#{specobj.name}-#{specobj.version}.gem"
    system("gem install #{gem}")
  end
  
end # class Gem::Commands::InsturlCommand
