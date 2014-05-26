# Keeps track of options and calls phantoimjs to run the render script.

# TODO: return pdf/png/etc as binary string instead of a file?
# TODO: support for renderBase64?
# TODO: support for injectjs?   http://phantomjs.org/tips-and-tricks.html
# TODO: how do I do something when a process exits?  Shrimple::Phantom.atexit { ... }  ?
# TODO: add a hard timeout
# TODO: wow --config=file sucks.  maybe add a way to specify cmdline args again?
#       either that or fix phantomjs...  https://github.com/ariya/phantomjs/issues/12265 https://github.com/ariya/phantomjs/issues/11775

# maybe:
# TODO: add an exit reason to Process?  :completed, :killed, :timeout?
# TODO: support casperjs?
# TODO: include lots of info about page load in logfile
# TODO: documentation!  probably using sdoc or yard?


require 'hashie/mash'
require 'shrimple/phantom'
require 'shrimple/default_config'


class Shrimple
  attr_accessor :options

  # allows setting config options directly on this object
  def method_missing name, *args, &block
    options.send(name, *args, &block)
  end


  def initialize opts={}
    @options = Hashie::Mash.new(Shrimple::DefaultConfig)
    @options.deep_merge!(opts)
    self.executable ||= self.class.default_executable
    self.renderer ||= self.class.default_renderer
  end


  def render_pdf src, *opts
    render src, Shrimple::DefaultPageSize, *opts
  end

  def render_png src, *opts
    render src, Shrimple::DefaultImageSize, {output_format: 'png'}, *opts
  end

  def render_jpeg src, *opts
    render src, Shrimple::DefaultImageSize, {output_format: 'jpeg'}, *opts
  end

  def render_gif src, *opts
    render src, Shrimple::DefaultImageSize, {output_format: 'gif'}, *opts
  end

  def render_text src, *opts
    render src, {renderer: File.expand_path('../render_text.js', __FILE__)}, *opts
  end

  def render src={}, *opts
    full_opts = get_full_options(src, *opts)
    phantom = Shrimple::Phantom.new(full_opts)
    phantom.wait unless full_opts[:background]
    phantom
  end

  def get_full_options src, *opts
    full_opts = Shrimple.deep_dup(options)
    full_opts.deep_merge!(src) if src && src.kind_of?(Hash)
    opts.each { |opt| full_opts.deep_merge!(opt) }
    full_opts.merge!(input: src) if src && !src.kind_of?(Hash)
    full_opts.merge!(output: full_opts.delete(:to)) if full_opts[:to]
    self.class.compact!(full_opts)
    full_opts
  end


  # how are these not a part of Hash?
  def self.compact! hash
    hash.delete_if { |k,v| v.nil? or (v.is_a?(Hash) && compact!(v).empty?) or (v.respond_to?('empty?') && v.empty?) }
  end

  def self.deep_dup hash
    Marshal.load(Marshal.dump(hash))
  end


  def self.processes
    @processes ||= Shrimple::ProcessMonitor.new
  end

  def self.default_renderer
    File.expand_path('../render.js', __FILE__)
  end
  
  def self.default_executable
    (defined?(Bundler::GemfileError) ? `bundle exec which phantomjs` : `which phantomjs`).chomp
  end
end
