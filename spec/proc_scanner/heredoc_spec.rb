require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Heredoc (wo indent)" do
  %w{X "X" 'X'}.each do |tag|

    should "handle <<#{tag}\\n .. \\nX\\n" do
      process(<<EOL
            s <<#{tag}
 aa 
X
EOL
             ).should.include("<<#{tag}\n aa \nX")
    end

    should "not handle <<#{tag} \\n .. \\nX\\n" do
      process(<<EOL
            s << #{tag}
 aa 
X
EOL
             ).should.not.include("<<#{tag} \n aa \nX")
    end

    should "not handle <<#{tag}\\n .. \\n X\\n" do
      process(<<EOL
            s <<#{tag}
 aa 
 X
EOL
             ).should.not.include("<<#{tag} \n aa \n X")
    end

    should "not handle <<#{tag}\\n .. \\nX \\n" do
      process(<<EOL
            s <<#{tag}
 aa
X 
EOL
             ).should.not.include("<<#{tag} \n aa \nX ")
    end

    should "not handle class <<#{tag}\\n .. \\nX \\n" do
      process(<<EOL
            class <<#{tag}
 aa 
X
EOL
             ).should.not.include("<<#{tag}\n aa \nX")
    end

    should "handle xclass <<#{tag}\\n .. \\nX \\n" do
      process(<<EOL
            xclass <<#{tag}
 aa 
X
EOL
             ).should.include("<<#{tag}\n aa \nX")
    end

    should "handle classx <<#{tag}\\n .. \\nX \\n" do
      process(<<EOL
            classx <<#{tag}
 aa 
X
EOL
             ).should.include("<<#{tag}\n aa \nX")
    end

    should "handle <<#{tag}\\n .. \\nX \\n" do
      process(<<EOL
<<#{tag}
 aa 
X
EOL
             ).should.include("<<#{tag}\n aa \nX")
    end

  end
end

describe "Heredoc (w indent)" do
  %w{X "X" 'X'}.each do |tag|

    should "handle <<-#{tag}\\n .. \\nX\\n" do
      process(<<EOL
            s <<-#{tag}
 aa 
X
EOL
             ).should.include("<<-#{tag}\n aa \nX")
    end

    should "handle <<-#{tag}\\n .. \\n X\\n" do
      process(<<EOL
            s <<-#{tag}
 aa 
 X
EOL
             ).should.include("<<-#{tag}\n aa \n X")
    end

    should "not handle <<-#{tag} \\n .. \\nX\\n" do
      process(<<EOL
            s <<-#{tag} 
 aa 
X
EOL
             ).should.not.include("<<-#{tag} \n aa \n X")
    end

    should "not handle <<-#{tag}\\n .. \\nX \\n" do
      process(<<EOL
            s <<-#{tag}
 aa 
X 
EOL
             ).should.not.include("<<-#{tag}\n aa \nX ")
    end

    should "not handle class <<-#{tag}\\n .. \\nX \\n" do
      process(<<EOL
            class <<-#{tag}
 aa 
X
EOL
             ).should.not.include("<<-#{tag}\n aa \nX")
    end

    should "handle xclass <<-#{tag}\\n .. \\nX \\n" do
      process(<<EOL
            xclass <<-#{tag}
 aa 
X
EOL
             ).should.include("<<-#{tag}\n aa \nX")
    end

    should "handle classx <<-#{tag}\\n .. \\nX \\n" do
      process(<<EOL
            classx <<-#{tag}
 aa 
X
EOL
             ).should.include("<<-#{tag}\n aa \nX")
    end

    should "handle <<-#{tag}\\n .. \\nX \\n" do
      process(<<EOL
<<-#{tag}
 aa 
X
EOL
             ).should.include("<<-#{tag}\n aa \nX")
    end

  end
end
