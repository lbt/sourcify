curr_dir = File.dirname(File.expand_path(__FILE__))
require File.join(curr_dir, '..', 'spec_helper')

ragel_dir = File.join(curr_dir, '..', '..', 'lib', 'sourcify', 'proc')
ragel_file = File.join(ragel_dir, 'scanner.rl')
ruby_file = File.join(ragel_dir, 'scanner.rb')
File.delete(ruby_file) rescue nil
system("ragel -R #{ragel_file}")

begin
  require File.join(ragel_dir, 'scanner.rb')
rescue LoadError
  raise $!
end

module Sourcify::Proc::Scanner
  class << self ; attr_reader :tokens ; end
end

def process(data)
  Sourcify::Proc::Scanner.process(data)
  Sourcify::Proc::Scanner.tokens
end
