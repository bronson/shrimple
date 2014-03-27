# Keeps track of options and calls the render script

# TODO: a background option that uses Prcoess.spawn?
# TODO: just send options as json
# TODO: return pdf as binary string instead of a file
# TODO: restore cookie functionality.  then tests!
# TODO: documentation!

# require 'json'
# require 'digest'
require 'open3'

class Shrimple
  class NoExecutableError < StandardError; end
  class RenderingError < StandardError; end

  attr_accessor :executable, :renderer, :options


  RenderScript = File.expand_path('../render.js', __FILE__)
  
  def self.default_executable
    (defined?(Bundler::GemfileError) ? `bundle exec which phantomjs` : `which phantomjs`).chomp
  end

  # Create a new render interface.
  # options:
  # - phantomjs: specifies the path to the phantomjs executable to use
  # - renderer: specifies the path to the render script to use
  def initialize options = {}
    defaults = {
      format: 'A4'
    }

    @executable = options.delete(:executable) || self.class.default_executable
    File.exists?(@executable) or raise NoExecutableError.new "No Executable Error: PhantomJS executable not found at #{@executable}.\n"
    @renderer = options.delete(:renderer) || RenderScript
    File.exists?(@renderer) or raise NoExecutableError.new "No Executable Error: render script not found at #{@renderer}.\n"
    @options = defaults.merge(options)
  end

  def render_pdf src, dst, options={}
    render src, dst, options.merge(output_format: 'pdf')
  end

  def render_png src, dst, option={}
    render src, dst, options.merge(output_format: 'png')
  end

  # generates and runs a phantomjs command
  def render src, dst, options={}
    cmdline = command(src, dst, options)
    execute(cmdline, options[:background])
  end

# semi-private

  def execute cmd, background=nil
    Open3.popen2e(*cmd) do |i,o,t|
      i.close
      output = o.read
      raise RenderingError.new("Rendering Error: #{cmd.join(' ')} returned #{t.value.exitstatus}: #{output}") unless t.value.success?
    end
  end

  # returns the command line that will invoke phantomjs
  def command src, dst, options
    options = options.dup
    options.delete(:background)  # remove runtime options

    opts = {input: src, output: dst}.merge(@options).merge(options)
    arg_list = opts.map {|key, value| ["-#{key}", value.to_s] }.flatten
    [executable, renderer, *arg_list]
  end

private
  
  def dump_cookies
    host = @source.url? ? URI::parse(@source.to_s).host : "/"
    json = @cookies.inject([]) { |a, (k, v)| 
        a.push({ :name => k, :value => v, :domain => host }); a 
      }.to_json
    @cookies_file = Tempfile.new(["shrimp", ".cookies"])
    @cookies_file.puts(json)
    @cookies_file.fsync
    @cookies_file.path
  end
end
