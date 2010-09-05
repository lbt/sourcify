# NOTE: The specs covered here are probably incomplete, and are added on an
# ad-hoc basis while writing ./scanner.rl.
require 'rubygems'
require 'bacon'
Bacon.summary_on_exit

rl_dir = File.join(File.dirname(File.expand_path(__FILE__)), '..');
rl_file = File.join(rl_dir, 'scanner.rl')
rb_file = File.join(rl_dir, 'scanner.rb')

File.delete(rb_file) rescue nil
system("ragel -R #{rl_file}")

begin
  require File.join(rl_dir, 'scanner.rb')
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

describe 'Single quote strings' do

  %w{~ ` ! @ # $ % ^ & * _ - + = \\ | ; : ' " , . ? /}.map{|w| [w,w] }.concat(
    [%w{( )}, %w{[ ]}, %w({ }), %w{< >}]
  ).each do |q1,q2|
    %w{q w}.each do |t|

      should "handle '%#{t}#{q1}...#{q2}' (wo escape (single))" do
        process(" xx %#{t}#{q1}hello#{q2} ").should.include("%#{t}#{q1}hello#{q2}")
      end

      should "handle '%#{t}#{q1}...#{q2}' (wo escape (multiple))" do
        tokens = process(" xx %#{t}#{q1}hello#{q2} %#{t}#{q1}world#{q2} ")
        tokens.should.include("%#{t}#{q1}hello#{q2}")
        tokens.should.include("%#{t}#{q1}world#{q2}")
      end

      should "handle '%#{t}#{q1}...#{q2}' (w escape (single))" do
        process(" xx %#{t}#{q1}hel\\#{q2}lo#{q2} ").should.include("%#{t}#{q1}hel\\#{q2}lo#{q2}")
      end

      should "handle '%#{t}#{q1}...#{q2}' (w escape (multiple))" do
        process(" xx %#{t}#{q1}h\\#{q2}el\\#{q2}lo#{q2} ").should.include("%#{t}#{q1}h\\#{q2}el\\#{q2}lo#{q2}")
      end

    end
  end

  should "handle '...' (wo escape (single))" do
    process(" xx 'hello' ").should.include("'hello'")
  end

  should "handle '...' (wo escape (multiple))" do
    tokens = process(" xx 'hello' 'world' ")
    tokens.should.include("'hello'")
    tokens.should.include("'world'")
  end

  should "handle '...' (w escape (single))" do
    process(" xx 'hel\\'lo' ").should.include("'hel\\'lo'")
  end

  should "handle '...' (w escape (multiple))" do
    process(" xx 'h\\'el\\'lo' ").should.include("'h\\'el\\'lo'")
  end

end

describe 'Double quote strings (wo interpolation)' do

  %w{~ ` ! @ # $ % ^ & * _ - + = \\ | ; : ' " , . ? /}.map{|w| [w,w] }.concat(
    [%w{( )}, %w{[ ]}, %w({ }), %w{< >}]
  ).each do |q1,q2|
    %w{Q W x r}.each do |t|

      should "handle '%#{t}#{q1}...#{q2}' (wo escape (single))" do
        process(" xx %#{t}#{q1}hello#{q2} ").should.include("%#{t}#{q1}hello#{q2}")
      end

      should "handle '%#{t}#{q1}...#{q2}' (wo escape (multiple))" do
        tokens = process(" xx  %#{t}#{q1}hello#{q2} %#{t}#{q1}world#{q2}  ")
        tokens.should.include("%#{t}#{q1}hello#{q2}")
        tokens.should.include("%#{t}#{q1}world#{q2}")
      end

      should "handle '%#{t}#{q1}...#{q2}' (w escape (single))" do
        process(" xx %#{t}#{q1}hel\\#{q2}lo#{q2} ").should.include("%#{t}#{q1}hel\\#{q2}lo#{q2}")
      end

      should "handle '%#{t}#{q1}...#{q2}' (w escape (multiple))" do
        process(" xx %#{t}#{q1}h\\#{q2}el\\#{q2}lo#{q2} ").should.include("%#{t}#{q1}h\\#{q2}el\\#{q2}lo#{q2}")
      end

    end
  end

  %w{" / `}.each do |q|

    should 'handle #{q}...#{q} (wo escape (single))' do
      process(%Q( xx #{q}hello#{q} )).should.include(%Q(#{q}hello#{q}))
    end

    should 'handle #{q}...#{q} (wo escape & multiple)' do
      tokens = process(%Q( xx #{q}hello#{q} #{q}world#{q} ))
      tokens.should.include(%Q(#{q}hello#{q}))
      tokens.should.include(%Q(#{q}world#{q}))
    end

    should 'handle #{q}...#{q} (w escape (single))' do
      process(%Q( xx #{q}hel\\#{q}lo#{q} )).should.include(%Q(#{q}hel\\#{q}lo#{q}))
    end

    should 'handle #{q}...#{q} (w escape (multiple))' do
      process(%Q( xx #{q}h\\#{q}el\\#{q}lo#{q} )).should.include(%Q(#{q}h\\#{q}el\\#{q}lo#{q}))
    end

  end

end

describe 'Commented lines' do

  should 'handle # ...' do
    process(<<EOL
      hello # blah
      world
EOL
    ).should.include("# blah")
  end

  should 'handle =begin ... =end' do
    process(<<EOL
      hello
=begin aa
bb
=end cc
      world
EOL
      ).should.include("\n=begin aa\nbb\n=end cc\n")
  end

end

describe 'Heredoc strings' do

  should 'handle <<-X\n .. \nX\n' do
    process(<<EOL
      aa
      s <<-X
        bb 
X
      cc
EOL
    ).should.include("<<-X\n        bb \nX")
  end

  should 'not handle <<-X\n .. \nX \n' do
    process(<<EOL
      aa
      s <<-X
        bb
X 
      cc
EOL
    ).should.not.include("<<-X\n        bb \nX ")
  end

  should 'handle <<-X\n .. \n  X\n' do
    process(<<EOL
      aa
      s <<-X
        bb 
  X
      cc
EOL
    ).should.include("<<-X\n        bb \n  X")
  end

  should 'not handle <<-X\n .. \n  X \n' do
    process(<<EOL
      aa
      s <<-X
        bb 
X 
      cc
EOL
    ).should.not.include("<<-X\n        bb \n  X ")
  end

  should 'handle <<X\n .. \nX' do
    process(<<EOL
      aa
      s <<X
        bb 
X
      cc
EOL
    ).should.include("<<X\n        bb \nX")
  end

  should 'not handle <<X\n .. \nX ' do
    process(<<EOL
      aa
      s <<X
        bb 
X 
      cc
EOL
    ).should.not.include("<<X\n        bb \nX ")
  end

  should 'not handle <<X\n .. \n  X' do
    process(<<EOL
      aa
      s <<X
        bb 
X
      cc
EOL
    ).should.not.include("<<X\n       bb \n  X")
  end

  should 'not handle class <<X ..' do
    process(<<EOL
      aa
      class <<X
        bb 
X
      cc
EOL
    ).should.not.include("<<X\n        bb \nX")
  end

  should 'handle xclass <<X ..' do
    process(<<EOL
      aa
      xclass <<X
        bb 
X
      cc
EOL
    ).should.include("<<X\n        bb \nX")
  end

end
