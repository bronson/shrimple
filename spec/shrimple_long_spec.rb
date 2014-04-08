require 'spec_helper'

# this file contains the time-consuming tests

def pdf_valid?(io)
  # quick & dirty check
  case io
    when File
      io.read[0...4] == "%PDF"
    when String
      io[0...4] == "%PDF" || File.open(io).read[0...4] == "%PDF"
  end
end


def prepare_file outfile
  File.delete(outfile) if File.exists?(outfile)
  outfile
end


# TODO: test a render.js that doesn't compile
# TODO: test PhantomJS failures

describe Shrimple do
  it "renders a gif to memory" do
    pending
  end

  it "renders a pdf to a file" do
    pending
    outfile = prepare_file('/tmp/shrimple-test-output.pdf')
    s = Shrimple.new
    s.render_pdf "file://#{example_html}", to: outfile
    expect(File.exists? outfile).to eq true
    expect(pdf_valid?(File.new(outfile))).to eq true
  end

  it "renders a png to a file" do
    pending
    # TODO: set the size of the png, then verify the size when done
    outfile = prepare_file('/tmp/shrimple-test-output.png')
    s = Shrimple.new
    p = s.render_png "file://#{example_html}", output: outfile
    expect(File.exists? outfile).to eq true
  end
end
