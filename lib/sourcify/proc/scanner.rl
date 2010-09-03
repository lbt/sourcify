module Sourcify
  module Proc
    module Scanner #:nodoc:all

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

    do_block_start   => { push(ts, te); increment(:do_block_start, :do_end) };
    do_block_end     => { push(ts, te); decrement(:do_block_end, :do_end) };
    do_block_nstart1 => { push(ts, te); increment(:do_block_nstart1, :do_end) };
    do_block_nstart2 => { push(ts, te); increment(:do_block_nstart2, :do_end) };

    modifier => { push(ts, te) };
    lbrace   => { push(ts, te) };
    rbrace   => { push(ts, te) };
    lparen   => { push(ts, te) };
    rparen   => { push(ts, te) };
    smcolon  => { push(ts, te); increment_line };
    newline  => { push(ts, te); increment_line };
    ^alnum   => { push(ts, te) };
    var      => { push(ts, te) };
    symbol   => { push(ts, te) };

    (' '+)   => { push(ts, te) };
    any      => { push(ts, te) };
  *|;

}%%
%% write data;

      class << self

        class Escape < Exception; end

        def process(data)
          begin
            reset_collectibles
            @results, @lineno = [], 1
            @data = data.unpack("c*")
            execute!
          rescue Escape
            @results
          end
        end

        def execute!
          data = @data
          eof = data.length
          %% write init;
          %% write exec;
        end

        def push(ts, te)
          @tokens << @data[ts .. te.pred].pack('c*')
        end

        def increment_line
          @lineno += 1
          raise Escape if @lineno > 1 && !@results.empty?
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
          when :do_block_nstart1 then @do_end_counter.increment
          when :do_block_nstart2 then @do_end_counter.increment(0..1)
          when :do_block_start
            unless @do_end_counter.started?
              @lineno = 1 # Fixing JRuby's lineno bug (see http://jira.codehaus.org/browse/JRUBY-5014)
              last = @tokens[-1]
              @tokens.clear
              @tokens << last
            end
            @do_end_counter.increment
          end
        end

        def decrement_do_end_counter
          return unless @do_end_counter.started?
          @do_end_counter.decrement
          construct_result_code if @do_end_counter.balanced?
        end

        def construct_result_code
          begin
            code = 'proc ' + @tokens.join
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

          attr_reader :counts

          def initialize
            @counts = [0,0]
          end

          def started?
            @counts.any?(&:nonzero?)
          end

          def balanced?
            @counts.any?(&:zero?)
          end

          def decrement
            (0..1).each{|i| @counts[i] -= 1 unless @counts[i].zero? }
          end

          def increment(val = 1)
            if val.is_a?(Range)
              @counts[0] += val.first
              @counts[1] += val.last
            else
              (0..1).each{|i| @counts[i] += 1 }
            end
          end

        end

      end

    end
  end
end
