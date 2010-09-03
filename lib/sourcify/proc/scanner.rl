require 'sourcify/proc/scanner_extensions'

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

      extend Scanner::Extensions

      def self.execute!
        data = @data
        eof = data.length
        %% write init;
        %% write exec;
      end

    end
  end
end
