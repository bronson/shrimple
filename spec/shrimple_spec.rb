require 'spec_helper'

describe Shrimple do
  it "automatically finds the executable and renderer" do
    s =  Shrimple.new
    expect(File.executable? s.executable).to be true
    expect(File.exists? s.renderer).to be true
  end

  it "can be told the executable and renderer" do
    # these don't need to be real executables since they're never called
    s = Shrimple.new(executable: '/bin/sh', renderer: example_html)
    expect(s.executable).to eq '/bin/sh'
    expect(s.renderer).to eq example_html
  end

  it "calls the right basic command line" do
    s = Shrimple.new
    s.should_receive(:execute).with(s.executable, s.renderer, '-input', 'infile', '-output', 'outfile', '-format', 'A4')
    s.run 'infile', 'outfile'
  end

  it "passes options" do
    s = Shrimple.new(executable: '/bin/sh', renderer: example_html, orientation: 'landscape')
    s.options['render_time'] = 55000
    s.should_receive(:execute).with('/bin/sh', example_html, '-input', 'infile', '-output', 'outfile', '-format', 'A4',
      '-orientation', 'landscape', '-render_time', '55000', '-zoom', '0.25', '-output_format', 'pdf' )
    s.render_pdf 'infile', 'outfile', zoom: 0.25
  end
end
