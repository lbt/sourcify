module Sourcify
  module Proc
    module Scanner

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
  newline       = '\n';

  assoc         = '=>';
  assgn         = '=';
  smcolon       = ';';
  spaces        = ' '*;
  line_start    = (newline | smcolon | lparen) . spaces;
  modifier      = (kw_if | kw_unless | kw_while | kw_until);

  do_block_start   = kw_do;
  do_block_end     = kw_end;
  do_block_nstart1 = line_start . (kw_if | kw_unless | kw_class | kw_module | kw_def | kw_begin | kw_case);
  do_block_nstart2 = line_start . (kw_while | kw_until | kw_for);

  main := |*

    do_block_start   => { push(k = :do_block_start, ts, te);   increment(k, :do_end) };
    do_block_end     => { push(k = :do_block_end, ts, te);     decrement(k, :do_end) };
    do_block_nstart1 => { push(k = :do_block_nstart1, ts, te); increment(k, :do_end) };
    do_block_nstart2 => { push(k = :do_block_nstart2, ts, te); increment(k, :do_end) };

    modifier => { push(:modifier, ts, te) };
    lbrace   => { push(:lbrace, ts, te) };
    rbrace   => { push(:rbrace, ts, te) };
    lparen   => { push(:lparen, ts, te) };
    rparen   => { push(:rparen, ts, te) };
    smcolon  => { push(:smcolon, ts, te); increment_line };
    newline  => { push(:newline, ts, te); increment_line };
    ^alnum   => { push(:any, ts, te) };
    var      => { push(:any, ts, te) };
    symbol   => { push(:any, ts, te) };

    (' '+)   => { push(:space, ts, te) };
    any      => { push(:any, ts, te) };
  *|;

}%%
%% write data;

      class << self

        def process(data)
          begin
            reset_collectibles
            @results, @lineno = [], 1
            @data = data = data.unpack("c*") if data.is_a?(String)
            eof = data.length

            %% write init;
            %% write exec;
          rescue Escape
            @results
          end
        end

        def push(key, ts, te)
          @tokens << [key, @data[ts .. te.pred].pack('c*')]
        end

        def increment_line
          @lineno += 1
        end

        def increment(type, key)
          send(:"increment_#{key}_counter", type)
        end

        def decrement(type, key)
          send(:"decrement_#{key}_counter")
        end

        def increment_do_end_counter(type)
          return if @brace_counter.started?
          case type
          when :do_end_nstart1 then @do_end_counter.increment
          when :do_end_nstart2 then @do_end_counter.increment(0..1)
          when :do_end_start
            unless @do_end_counter.started?
              @lineno = 1 # JRuby has lineno bug (see http://jira.codehaus.org/browse/JRUBY-5014)
              last = @tokens[-1]
              @tokens.clear
              @tokens << last
            end
            @do_end_counter.increment
          end
        end

        def decrement_do_end_counter
          return if @brace_counter.started?
          @do_end_counter.decrement
          construct_result_code if @do_end_counter.balanced?
        end

        def construct_result_code
          begin
            code = 'proc ' + @tokens.map(&:last).join
            eval(code) # TODO: is there a better way to check for SyntaxError ?
            @results << code
            raise Escape unless @lineno == 1
            reset_collectibles
          rescue SyntaxError
          end
        end

        def reset_collectibles
          @tokens = []
          @do_end_counter = Counter.new
          @brace_counter = Counter.new
        end

        class Counter

          def initialize
            @counts = [0,0]
          end

          def started?
            @counts.any(&:nonzero?)
          end

          def balanced?
            @counts.any(&:zero?)
          end

          def decrement
            @counts[0] -= 1
            @counts[1] -= 1
          end

          def increment(val = 1)
            if val.is_a?(Range)
              @counts[0] += val.first
              @counts[1] += val.last
            else
              @counts[0] += 1
              @counts[0] += 1
            end
          end

        end

      end

    end
  end
end
#
#if $0 == __FILE__
#  require 'rubygems'
#  require 'bacon'
#  Bacon.summary_on_exit
#  process = Sourcify::Proc::Ragel.method(:process)
#
#  %w{while until if unless}.each do |kw|
#    describe "Proc machine handling if-like keyword (#{kw})" do
#
#      class << self
#        def should_handle_as_block_like(str)
#          tokens = Sourcify::Proc::Ragel.process(str)[:tokens].map(&:first)
#          tokens.should.not.include(:kw_modifier)
#          tokens.should.include(:"kw_for")
#        end
#        def should_handle_as_modifier(str)
#          tokens = Sourcify::Proc::Ragel.process(str)[:tokens].map(&:first)
#          tokens.should.include(:kw_modifier)
#          tokens.should.not.include(:"kw_if")
#          tokens.should.not.include(:"kw_for")
#        end
#      end
#
#    end
#  end
#
#  %w{while until for}.each do |kw|
#    describe "Proc machine handling for-like keyword (#{kw})" do
#
#      class << self
#        def should_handle_as_block_like(str)
#          tokens = Sourcify::Proc::Ragel.process(str)[:tokens].map(&:first)
#          tokens.should.not.include(:kw_modifier)
#          tokens.should.include(:"kw_for")
#        end
#        def should_handle_as_modifier(str)
#          tokens = Sourcify::Proc::Ragel.process(str)[:tokens].map(&:first)
#          tokens.should.include(:kw_modifier)
#          tokens.should.not.include(:"kw_if")
#          tokens.should.not.include(:"kw_for")
#        end
#      end
#
#      should "handle ... #{kw} ... as modifier" do
#        should_handle_as_modifier("
#          x = 1 #{kw} true
#        ")
#      end
#
#      should "handle ... (... #{kw} ...) as modifier" do
#        should_handle_as_modifier("
#          y = (x = 1 #{kw} true)
#        ")
#      end
#
#      should "handle ...; ... #{kw} ... as modifier" do
#        should_handle_as_modifier("
#          y = 2; x = 1 #{kw} true
#        ")
#      end
#
#      should "handle #{kw} ... as block-like" do
#        should_handle_as_block_like("
#          #{kw} true do x = 1 end
#        ")
#      end
#
#      should "handle ... (#{kw} ...) as block-like" do
#        should_handle_as_block_like("
#          y = (#{kw} true do x = 1 end)
#        ")
#      end
#
#      should "handle ...; #{kw} ... as block-like" do
#        should_handle_as_block_like("
#          y = 2; #{kw} true do x = 1 end
#        ")
#      end
#
#      should "handle #{kw} ... \\n as block-like" do
#        should_handle_as_block_like("
#          #{kw} true
#            x = 1
#          end
#        ")
#      end
#
#      should "handle ... (#{kw} ... \\n ...) as block-like" do
#        should_handle_as_block_like("
#          y = (#{kw} true
#              x = 1
#            end
#          )
#        ")
#      end
#
#      should "handle ...; #{kw} ... \\n ... as block like" do
#        should_handle_as_block_like("
#          y = 2; #{kw} true
#              x = 1
#            end
#        ")
#      end
#
#      should "handle #{kw} ...; ... as block-like" do
#        should_handle_as_block_like("
#          #{kw} true; x = 1; end
#        ")
#      end
#
#      should "handle ... (#{kw} ...; ...) as block-like" do
#        should_handle_as_block_like("
#          y = (#{kw} true; x = 1; end)
#        ")
#      end
#
#      should "handle ...; #{kw} ...; ... as block-like" do
#        should_handle_as_block_like("
#          y = 2; #{kw} true; x = 1; end
#        ")
#      end
#
#    end
#  end
#
#  %w{do end class module def begin case}.each do |kw|
#    describe "Proc machine handling keyword '#{kw}'" do
#
#      [
#        "#{kw}", " #{kw}", "#{kw} ", " #{kw} ",
#        "#{kw}\n", " #{kw}\n",
#        "\n#{kw}", "\n#{kw} ",
#        ")#{kw}", ")#{kw} ",
#        "}#{kw}", "}#{kw} ",
#        "]#{kw}", "]#{kw} ",
#        "#{kw}|", " #{kw}|",
#        "#{kw}(", " #{kw}(",
#        "#{kw}{", " #{kw}{",
#        "#{kw}[", " #{kw}[",
#      ].each do |frag|
#        should "handle '#{frag}'" do
#          result = process.call(frag)
#          result[:tokens].should.include([:"kw_#{kw}", kw])
#          result[:counters][0].count.should.equal(kw == 'end' ? -1 : 1)
#        end
#      end
#
#      [
#        ":#{kw}", ":#{kw} ",
#        "a#{kw}", "a#{kw} ",
#        "#{kw}a", " #{kw}a",
#        "_#{kw}", "_#{kw} ",
#        "#{kw}_", " #{kw}_",
#      ].each do |frag|
#        should "not handle '#{frag}'" do
#          result = process.call(frag)
#          result[:tokens].should.not.include([:"kw_#{kw}", kw])
#          result[:counters][0].count.should.equal(0)
#        end
#      end
#
#    end
#  end
#
#  describe "Proc machine handling newlining" do
#
#    should "handle newline" do
#      process.call("
#        hello
#        world
#      ")[:lineno].should.equal(4)
#    end
#
#    should "handle escaped newline" do
#      process.call("
#        hello \
#        world
#      ")[:lineno].should.equal(3)
#    end
#
#    should "handle semi-colon" do
#      process.call("
#        hello; world
#      ")[:lineno].should.equal(4)
#    end
#
#  end
#
#
##  describe "Proc machine handling symbol" do
##
##    [
##      ":aa", ":aa ", " :aa", " :aa ",
##      ":aa\n", " :aa\n", "\n:aa", "\n:aa ", "\n:aa\n",
##    ].each do |frag|
##      should "handle '#{frag}'" do
##        Sourcify::Proc::Ragel.process(frag).should.include([:symbol, ":aa"])
##      end
##    end
##
##    [
##      ":~", ":`", ":%", ":^", ":&", ":*", ":-", ":+", ":_", ":/", ":<", ":>", ":|",
##      ":@aa", ":@@aa", ":$aa",
##    ].each do |frag|
##      should "handle '#{frag}'" do
##        Sourcify::Proc::Ragel.process(frag).should.include([:symbol, frag])
##      end
##    end
##
##    [
##      ":!", ":@", ":#", ":$", ":(", ":)", ":=", ":\\", ":{", ":}",
##      ":[", ":]", "::", ":;", ':"', ":'", ":?", ":,", ":."
##    ].each do |frag|
##      should "not handle '#{frag}'" do
##        Sourcify::Proc::Ragel.process(frag).should.not.include([:symbol, frag])
##      end
##    end
##
##  end
##
##  describe "Proc machine handling namespace" do
##
##    ['::', ':::'].each do |frag|
##      should "handle '#{frag}'" do
##        Sourcify::Proc::Ragel.process(frag).should.include([:any, '::'])
##      end
##    end
##
##    should "not handle ':'" do
##      Sourcify::Proc::Ragel.process(frag).should.not.include([:any, '::'])
##    end
##
##  end
#
##      [
##        ":#{kw}", ":#{kw} ",
##        "a#{kw}", "a#{kw} ",
##        "#{kw}a", " #{kw}a",
##        "_#{kw}", "_#{kw} ",
##        "#{kw}_", " #{kw}_",
##      ].each do |frag|
##        should "not handle '#{frag}'" do
##          Sourcify::Proc::Ragel.process(frag).should.not.include([:"kw_#{kw}", kw])
##        end
##      end
##
##    end
##  end
#
#
#end
