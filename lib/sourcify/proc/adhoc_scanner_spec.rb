# NOTE: The specs covered here are probably incomplete, and are added on an
# ad-hoc basis while writing ./scanner.rl.
require 'rubygems'
require 'bacon'
Bacon.summary_on_exit

rl_dir = File.dirname(File.expand_path(__FILE__));
rl_file = File.join(rl_dir, 'scanner.rl')
rb_file = File.join(rl_dir, 'scanner.rb')

File.delete(rb_file) rescue nil
system("ragel -R #{rl_file}")

begin
  require File.join(rl_dir, 'scanner_extensions.rb')
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

      should "handle '%#{t}#{q1}...#{q2}' (wo escape)" do
        process(<<-EOL
          %#{t}#{q1}hello#{q2}
EOL
        ).should.include((<<-EOL
          %#{t}#{q1}hello#{q2}
EOL
        ).strip)
      end

#        should "handle '%#{t}#{q1}...#{q2}' (w escape)" do
#          process(<<-EOL
#            %#{t}#{q1}hel\\#{q2}lo#{q2}
#EOL
#          ).should.include((<<-EOL
#            %#{t}#{q1}hel\\#{q2}lo#{q2}
#EOL
#          ).strip)
#        end

      should "handle '%#{t}#{q1}...#{q2}' (wo escape & multiple)" do
        process(<<-EOL
          %#{t}#{q1}hello#{q2} %#{t}#{q1}world#{q2}
EOL
        ).should.include((<<-EOL
          %#{t}#{q1}hello#{q2}
EOL
        ).strip)
      end

    end
  end

  should "handle '...' (wo escape)" do
    process(<<-EOL
      'hello'
EOL
    ).should.include((<<-EOL
      'hello'
EOL
    ).strip)
  end

#    should "handle '...' (w escape)" do
#      process(<<-EOL
#        'hel\'lo'
#EOL
#      ).should.include((<<-EOL
#        'hel\'lo'
#EOL
#      ).strip)
#    end

  should "handle '...' (wo escape & multiple)" do
    process(<<-EOL
      'hello' 'world'
EOL
    ).should.include((<<-EOL
      'hello'
EOL
    ).strip)
  end

end

describe 'Double quote strings (wo interpolation)' do

  %w{~ ` ! @ # $ % ^ & * _ - + = \\ | ; : ' " , . ? /}.map{|w| [w,w] }.concat(
    [%w{( )}, %w{[ ]}, %w({ }), %w{< >}]
  ).each do |q1,q2|
    %w{Q W x r}.each do |t|

      should "handle '%#{t}#{q1}...#{q2}' (wo escape)" do
        process(<<-EOL
          %#{t}#{q1}hello#{q2}
EOL
        ).should.include((<<-EOL
          %#{t}#{q1}hello#{q2}
EOL
        ).strip)
      end

#        should "handle '%#{t}#{q1}...#{q2}' (w escape)" do
#          process(<<-EOL
#            %#{t}#{q1}hel\\#{q2}lo#{q2}
#EOL
#          ).should.include((<<-EOL
#            %#{t}#{q1}hel\\#{q2}lo#{q2}
#EOL
#          ).strip)
#        end

      should "handle '%#{t}#{q1}...#{q2}' (wo escape & multiple)" do
        process(<<-EOL
          %#{t}#{q1}hello#{q2} %#{t}#{q1}world#{q2}
EOL
        ).should.include((<<-EOL
          %#{t}#{q1}hello#{q2}
EOL
        ).strip)
      end

    end
  end

  %w{" / `}.each do |q|

    should 'handle #{q}...#{q} (wo escape)' do
      process(<<-EOL
        #{q}hello#{q}
EOL
      ).should.include((<<-EOL
        #{q}hello#{q}
EOL
      ).strip)
    end

    should 'handle #{q}...#{q} (wo escape & multiple)' do
      process(<<-EOL
        #{q}hello#{q} #{q}world#{q}
EOL
      ).should.include((<<-EOL
        #{q}hello#{q}
EOL
      ).strip)
    end

#      should 'handle #{q}...#{q} (w escape)' do
#        process(<<-EOL
#          #{q}hel\#{q}lo#{q}
#EOL
#        ).should.include((<<-EOL
#          #{q}hel\#{q}lo#{q}
#EOL
#        ).strip)
#      end

  end

end

describe 'Commented lines' do

  should 'handle # ...' do
    process(<<EOL
      hello # blah
      world
EOL
    ).should.include("# blah\n")
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
    ).should.include("<<-X\n        bb \nX\n")
  end

  should 'not handle <<-X\n .. \nX \n' do
    process(<<EOL
      aa
      s <<-X
        bb
X 
      cc
EOL
    ).should.not.include("<<-X\n        bb \nX \n")
  end

  should 'handle <<-X\n .. \n  X\n' do
    process(<<EOL
      aa
      s <<-X
        bb 
  X
      cc
EOL
    ).should.include("<<-X\n        bb \n  X\n")
  end

  should 'not handle <<-X\n .. \n  X \n' do
    process(<<EOL
      aa
      s <<-X
        bb 
X 
      cc
EOL
    ).should.not.include("<<-X\n        bb \n  X \n")
  end

  should 'handle <<X\n .. \nX' do
    process(<<EOL
      aa
      s <<X
        bb 
X
      cc
EOL
    ).should.include("<<X\n        bb \nX\n")
  end

  should 'not handle <<X\n .. \nX ' do
    process(<<EOL
      aa
      s <<X
        bb 
X 
      cc
EOL
    ).should.not.include("<<X\n        bb \nX \n")
  end

  should 'not handle <<X\n .. \n  X' do
    process(<<EOL
      aa
      s <<X
        bb 
X
      cc
EOL
    ).should.not.include("<<X\n       bb \n  X\n")
  end

  should 'not handle class <<X ..' do
    process(<<EOL
      aa
      class <<X
        bb 
X
      cc
EOL
    ).should.not.include("<<X\n        bb \nX\n")
  end

  should 'handle xclass <<X ..' do
    process(<<EOL
      aa
      xclass <<X
        bb 
X
      cc
EOL
    ).should.include("<<X\n        bb \nX\n")
  end

end
