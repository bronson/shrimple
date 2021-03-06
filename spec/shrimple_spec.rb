require 'spec_helper'

# Mostly tests the Shrimple API.  Other specs test the internals.


describe Shrimple do
  # we send this in every request until Phantom fixes its bug, see default_config.rb
  let(:custom_headers) { {"page" => {"customHeaders"=>{"Accept-Encoding"=>"identity"}}} }

  it "automatically finds the executable and renderer" do
    s = Shrimple.new
    expect(File.executable? s.executable).to be true
    expect(File.exists? s.renderer).to be true
  end

  it "can be told the executable and renderer" do
    # these don't need to be real executables since they're never called
    s = Shrimple.new(executable: '/bin/sh', renderer: example_html)
    expect(s.executable).to eq '/bin/sh'
    expect(s.renderer).to eq example_html
  end

  it "dies if specified executable can't be found" do
    s = Shrimple.new(executable: '/bin/THIS_FILE_DOES.not.Exyst')
    expect { s.render 'http://be.com' }.to raise_exception(/[Nn]o such file/)
  end

  it "dies if default executable can't be found" do
    expect { Shrimple.new.render('http://be.com', executable: nil) }.to raise_exception(/PhantomJS not found/)
  end

  it "allows a bunch of different ways to set options" do
    s = Shrimple.new(executable: '/bin/sh', renderer: example_html, render: {quality: 50})

    s.executable = '/bin/cat'
    s.page.paperSize.orientation = 'landscape'
    s[:page][:settings][:userAgent] = 'webkitalike'
    s.options.page.zoomFactor = 0.25

    mock_phantom = Object.new
    expect(mock_phantom).to receive(:wait).once

    allow(Shrimple::Phantom).to receive(:new).once do |opts|
      expect(opts.to_hash).to eq(Hashie::Mash.new({
        input: 'infile',
        output: 'outfile',
        executable: '/bin/cat',
        renderer: example_html,
        render: { quality: 50 },
        page: {
          paperSize: { orientation: 'landscape' },
          settings: { userAgent: 'webkitalike' },
          zoomFactor: 0.25
        }
      }).merge(custom_headers).to_hash)
      mock_phantom
    end

    s.render 'infile', to: 'outfile'
  end

  it "runs in the background" do
    s = Shrimple.new(executable: '/bin/cat', renderer: 'tt.js', background: true)

    mock_phantom = Object.new
    expect(mock_phantom).not_to receive(:wait)
    allow(Shrimple::Phantom).to receive(:new).once.and_return(mock_phantom)

    p = s.render 'infile'
  end

  it "special-cases input as the first argument" do
    s = Shrimple.new
    s.merge!(executable: nil, renderer: nil)
    # can either start with a value for input
    expect(s.get_full_options("input", to: "output")).
      to eq({'input' => 'input', 'output' => 'output'}.merge(custom_headers))
    # or just use hashes all the way through
    expect(s.get_full_options(input: "eenput", output: "ootput")).
      to eq({'input' => 'eenput', 'output' => 'ootput'}.merge(custom_headers))
  end

  it "has options with indifferent access" do
    s = Shrimple.new
    s.merge!('executable' => nil, renderer: nil)
    expect(s.get_full_options(executable: 'symbol', 'executable' => 'string')).to eq({'executable' => 'string'}.merge(custom_headers))
    s.merge!(executable: 'symbol')
    expect(s.get_full_options(executable: 'symbol')).to eq({'executable' => 'symbol'}.merge(custom_headers))
    expect(Shrimple.compact!(s.to_hash)).to eq({'executable' => 'symbol'}.merge(custom_headers))
  end

  it "properly merges callbacks" do
    # this is in response to a bug where it was impossible to pass onSuccess/onError directly to render
    s = Shrimple.new
    s.merge!('executable' => nil, renderer: nil) # can't pass to constructor since nil means use default
    expect(s.get_full_options(onSuccess: 4, onError: 5)).to eq({'onSuccess' => 4, 'onError' => 5}.merge(custom_headers))
  end

  it "has a working compact" do
    expect(Shrimple.compact!({
      a: nil,
      b: { c: nil },
      d: { e: { f: "", g: 1 } },
      h: false
    })).to eq({
      d: { e: { g: 1 }},
      h: false
    })

    expect(Shrimple.compact!({})).to eq({})
  end

  it "has a working deep_dup" do
    x = { a: 1, b: { c: 2, d: false, e:[1,2,3] }}
    y = Shrimple.deep_dup(x)

    x[:a] = 2
    x[:b].delete(:e)
    x[:b][:d] = true
    x.delete(:b)

    # y should be unchanged since we dup'd it
    expect(x).to eq({a: 2})
    expect(y).to eq({a: 1, b: { c: 2, d: false, e: [1, 2, 3] }})
  end
end
