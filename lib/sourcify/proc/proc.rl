module Sourcify
  module Proc
    module Ragel

      class Escape < Exception; end

%%{
  machine proc;

  kw_do         = 'do';
  kw_end        = 'end';
  kw_begin      = 'begin';
  kw_case       = 'case';
  kw_while      = 'while';
  kw_until      = 'until';
  kw_for        = 'for';
  kw_if         = 'if';
  kw_unless     = 'unless';
  kw_class      = 'class';
  kw_module     = 'module';
  kw_def        = 'def';
  kw_while_do   = '';
  kw_for_do     = '';
  kw_until_do   = '';

  lbrace        = '{';
  rbrace        = '}';
#  lparen        = '(';
#  rparen        = ')';
#  lbracket      = '[';
#  rbracket      = ']';

  var           = [a-z_][a-zA-Z0-9_]*;
  symbol        = ':' . var;

  assoc         = '=>';
  assgn         = '=';

  main := |*

      lbrace   => { emit(:lbrace, data, ts, te) };
      rbrace   => { emit(:rbrace, data, ts, te) };

      kw_do => { emit(:kw_do, data, ts, te) };
      kw_end => { emit(:kw_end, data, ts, te) };
      kw_class => { emit(:kw_class, data, ts, te) };
      kw_module => { emit(:kw_module, data, ts, te) };
      kw_def => { emit(:kw_def, data, ts, te) };
      kw_while => { emit(:kw_while, data, ts, te) };
      kw_until => { emit(:kw_until, data, ts, te) };
      kw_begin => { emit(:kw_begin, data, ts, te) };
      kw_case => { emit(:kw_case, data, ts, te) };
      kw_for => { emit(:kw_for, data, ts, te) };
      kw_if => { emit(:kw_if, data, ts, te) };
      kw_unless => { emit(:kw_unless, data, ts, te) };

      var => { emit(:any, data, ts, te) };
      symbol => { emit(:any, data, ts, te) };
      ^alnum => { emit(:any, data, ts, te) };

#      lparen   => { emit(:lparen, data, ts, te) };
#      rparen   => { emit(:rparen, data, ts, te) };
#      lbracket => { emit(:any, data, ts, te) };
#      rbracket => { emit(:any, data, ts, te) };

      space+ => { emit(:space, data, ts, te) };
      #any    => { emit(:any, data, ts, te) };
  *|;

}%%
%% write data;

      class << self

        def process(data)
          begin
            data = data.unpack("c*") if data.is_a?(String)
            eof = data.length
            @tokens = []
            %% write init;
            %% write exec;
            @tokens
          rescue Escape
            @tokens
          end
        end

        def emit(key, data, ts, te)
          @tokens << [key, data[ts .. te.pred].pack('c*')]
        end

      end

    end
  end
end

if $0 == __FILE__
  require 'rubygems'
  require 'bacon'
  Bacon.summary_on_exit

  %w{do end class module def begin case if unless while until for}.each do |kw|
    describe "Proc machine handling keyword '#{kw}'" do

      [
        "#{kw}", " #{kw}", "#{kw} ", " #{kw} ",
        "#{kw}\n", " #{kw}\n",
        "\n#{kw}", "\n#{kw} ",
        ")#{kw}", ")#{kw} ",
        "}#{kw}", "}#{kw} ",
        "]#{kw}", "]#{kw} ",
        "#{kw}|", " #{kw}|",
        "#{kw}(", " #{kw}(",
        "#{kw}{", " #{kw}{",
        "#{kw}[", " #{kw}[",
      ].each do |frag|
        should "handle '#{frag}'" do
          Sourcify::Proc::Ragel.process(frag).should.include([:"kw_#{kw}", kw])
        end
      end

      [
        ":#{kw}", ":#{kw} ",
        "a#{kw}", "a#{kw} ",
        "#{kw}a", " #{kw}a",
        "_#{kw}", "_#{kw} ",
        "#{kw}_", " #{kw}_",
      ].each do |frag|
        should "not handle '#{frag}'" do
          Sourcify::Proc::Ragel.process(frag).should.not.include([:"kw_#{kw}", kw])
        end
      end

    end
  end


#  describe "Proc machine handling symbol" do
#
#    [
#      ":aa", ":aa ", " :aa", " :aa ",
#      ":aa\n", " :aa\n", "\n:aa", "\n:aa ", "\n:aa\n",
#    ].each do |frag|
#      should "handle '#{frag}'" do
#        Sourcify::Proc::Ragel.process(frag).should.include([:symbol, ":aa"])
#      end
#    end
#
#    [
#      ":~", ":`", ":%", ":^", ":&", ":*", ":-", ":+", ":_", ":/", ":<", ":>", ":|",
#      ":@aa", ":@@aa", ":$aa",
#    ].each do |frag|
#      should "handle '#{frag}'" do
#        Sourcify::Proc::Ragel.process(frag).should.include([:symbol, frag])
#      end
#    end
#
#    [
#      ":!", ":@", ":#", ":$", ":(", ":)", ":=", ":\\", ":{", ":}",
#      ":[", ":]", "::", ":;", ':"', ":'", ":?", ":,", ":."
#    ].each do |frag|
#      should "not handle '#{frag}'" do
#        Sourcify::Proc::Ragel.process(frag).should.not.include([:symbol, frag])
#      end
#    end
#
#  end
#
#  describe "Proc machine handling namespace" do
#
#    ['::', ':::'].each do |frag|
#      should "handle '#{frag}'" do
#        Sourcify::Proc::Ragel.process(frag).should.include([:any, '::'])
#      end
#    end
#
#    should "not handle ':'" do
#      Sourcify::Proc::Ragel.process(frag).should.not.include([:any, '::'])
#    end
#
#  end

#      [
#        ":#{kw}", ":#{kw} ",
#        "a#{kw}", "a#{kw} ",
#        "#{kw}a", " #{kw}a",
#        "_#{kw}", "_#{kw} ",
#        "#{kw}_", " #{kw}_",
#      ].each do |frag|
#        should "not handle '#{frag}'" do
#          Sourcify::Proc::Ragel.process(frag).should.not.include([:"kw_#{kw}", kw])
#        end
#      end
#
#    end
#  end


end
