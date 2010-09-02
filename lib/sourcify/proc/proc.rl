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

  lbrace        = '{';
  rbrace        = '}';
  lparen        = '(';
  rparen        = ')';

  var           = [a-z_][a-zA-Z0-9_]*;
  symbol        = ':' . var;

  assoc         = '=>';
  assgn         = '=';

  main := |*

      lbrace   => { push(:lbrace, data, ts, te) };
      rbrace   => { push(:rbrace, data, ts, te) };
      lparen   => { push(:lparen, data, ts, te) };
      rparen   => { push(:rparen, data, ts, te) };

      kw_do => { push(k = :kw_do, data, ts, te); increment(k,0) };
      kw_end => { push(k = :kw_end, data, ts, te); decrement(k,0) };
      kw_class => { push(k = :kw_class, data, ts, te); increment(k,0) };
      kw_module => { push(k = :kw_module, data, ts, te); increment(k,0) };
      kw_def => { push(k = :kw_def, data, ts, te); increment(k,0) };
      kw_while => { push(k = :kw_while, data, ts, te); increment(k,0) };
      kw_until => { push(k = :kw_until, data, ts, te); increment(k,0) };
      kw_begin => { push(k = :kw_begin, data, ts, te); increment(k,0) };
      kw_case => { push(k = :kw_case, data, ts, te); increment(k,0) };
      kw_for => { push(k = :kw_for, data, ts, te); increment(k,0) };
      kw_if => { push(k = :kw_if, data, ts, te); increment(k,0) };
      kw_unless => { push(k = :kw_unless, data, ts, te); increment(k,0) };

      var => { push(:any, data, ts, te) };
      symbol => { push(:any, data, ts, te) };
      ^alnum => { push(:any, data, ts, te) };

      space+ => { push(:space, data, ts, te) };
      #any    => { push(:any, data, ts, te) };
  *|;

}%%
%% write data;

      class << self

        def process(data)
          begin
            @tokens = []
            @counters = {0 => Counter.new, 1 => Counter.new}
            data = data.unpack("c*") if data.is_a?(String)
            eof = data.length

            %% write init;
            %% write exec;

            {
              :tokens => @tokens,
              :counters => @counters
            }
          rescue Escape
            @tokens
          end
        end

        def push(key, data, ts, te)
          @tokens << [key, data[ts .. te.pred].pack('c*')]
        end

        def increment(type, key)
          @counters[key].increment
        end

        def decrement(type, key)
          @counters[key].decrement
        end

        class Counter
          attr_reader    :count
          def initialize ; @count = 0      ; end
          def started?   ; @count.nonzero? ; end
          def increment  ; @count += 1     ; end
          def decrement  ; @count -= 1     ; end
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

      process = Sourcify::Proc::Ragel.method(:process)

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
          result = process.call(frag)
          result[:tokens].should.include([:"kw_#{kw}", kw])
          result[:counters][0].count.should.equal(kw == 'end' ? -1 : 1)
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
          result = process.call(frag)
          result[:tokens].should.not.include([:"kw_#{kw}", kw])
          result[:counters][0].count.should.equal(0)
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
