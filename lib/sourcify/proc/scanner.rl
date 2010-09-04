begin
  require 'sourcify/proc/scanner_extensions'
rescue LoadError
  # Happens when running tests at end of file
  require 'scanner_extensions'
end

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

  lvar          = [a-z_][a-zA-Z0-9_]*;
  ovars         = ('@' | '@@' | '$') . lvar;
  symbol        = ':' . (lvar | ovars);
  label         = lvar . ':';
  newline       = '\n';

  assoc         = '=>';
  assgn         = '=';
  smcolon       = ';';
  spaces        = ' '*;
  line_start    = (newline | smcolon | lparen) . spaces;
  modifier      = (kw_if | kw_unless | kw_while | kw_until);
  squote        = "'";
  dquote        = '"';

  line_comment  = '#' . ^newline* . newline;
  block_comment = newline . '=begin' . ^newline* . newline . any* . newline . '=end' . ^newline* . newline;
  comments      = (line_comment | block_comment);

#  hash19        = lbrace . (^rbrace)* . label . (^rbrace)* . rbrace;
#  hash18        = lbrace . (^rbrace)* . assoc . (^rbrace)* . rbrace;

  do_block_start    = kw_do;
  do_block_end      = kw_end;
  do_block_nstart1  = line_start . (kw_if | kw_unless | kw_class | kw_module | kw_def | kw_begin | kw_case);
  do_block_nstart2  = line_start . (kw_while | kw_until | kw_for);

  brace_block_start = lbrace;
  brace_block_end   = rbrace;

#  qs1  = '~' . (^'~' | '\~')* . '~';  qs2  = '`' . (^'`' | '\`')* . '`';
#  qs3  = '!' . (^'!' | '\!')* . '!';  qs4  = '@' . (^'@' | '\@')* . '@';
#  qs5  = '#' . (^'#' | '\#')* . '#';  qs6  = '$' . (^'$' | '\$')* . '$';
#  qs7  = '%' . (^'%' | '\%')* . '%';  qs8  = '^' . (^'^' | '\^')* . '^';
#  qs9  = '&' . (^'&' | '\&')* . '&';  qs10 = '*' . (^'*' | '\*')* . '*';
#  qs11 = '-' . (^'-' | '\-')* . '-';  qs12 = '_' . (^'_' | '\_')* . '_';
#  qs13 = '+' . (^'+' | '\+')* . '+';  qs14 = '=' . (^'=' | '\=')* . '=';
#  qs15 = '<' . (^'>' | '\>')* . '>';  qs16 = '|' . (^'|' | '\|')* . '|';
#  qs17 = ':' . (^':' | '\:')* . ':';  qs18 = ';' . (^';' | '\;')* . ';';
#  qs19 = '"' . (^'"' | '\"')* . '"';  qs20 = "'" . (^"'" | "\'")* . "'";
#  qs21 = ',' . (^',' | '\,')* . ',';  qs22 = '.' . (^'.' | '\.')* . '.';
#  qs23 = '?' . (^'?' | '\?')* . '?';  qs24 = '/' . (^'/' | '\/')* . '/';
#  qs25 = '{' . (^'}' | '\}')* . '}';  qs26 = '[' . (^']' | '\]')* . ']';
#  qs27 = '(' . (^')' | '\)')* . ')';  qs28 = '\\' . (^'\\' | '\\\\')* . '\\';

  qs1  = '~' . [^\~]* . '~';  qs2  = '`' . [^\`]* . '`';
  qs3  = '!' . [^\!]* . '!';  qs4  = '@' . [^\@]* . '@';
  qs5  = '#' . [^\#]* . '#';  qs6  = '$' . [^\$]* . '$';
  qs7  = '%' . [^\%]* . '%';  qs8  = '^' . [^\^]* . '^';
  qs9  = '&' . [^\&]* . '&';  qs10 = '*' . [^\*]* . '*';
  qs11 = '-' . [^\-]* . '-';  qs12 = '_' . [^\_]* . '_';
  qs13 = '+' . [^\+]* . '+';  qs14 = '=' . [^\=]* . '=';
  qs15 = '<' . [^\>]* . '>';  qs16 = '|' . [^\|]* . '|';
  qs17 = ':' . [^\:]* . ':';  qs18 = ';' . [^\;]* . ';';
  qs19 = '"' . [^\"]* . '"';  qs20 = "'" . [^\']* . "'";
  qs21 = ',' . [^\,]* . ',';  qs22 = '.' . [^\.]* . '.';
  qs23 = '?' . [^\?]* . '?';  qs24 = '/' . [^\/]* . '/';
  qs25 = '{' . [^\}]* . '}';  qs26 = '[' . [^\]]* . ']';
  qs27 = '(' . [^\)]* . ')';  qs28 = '\\' . [^\\]* . '\\';

  # NASTY mess for single quoted strings
  sqs      = ('%q' | '%w');
#  sq_str1  = "'" . (^"'" | "\\'")? . "'";
  sq_str1  = "'" . [^\']* . "'";
  sq_str2  = sqs . qs1;   sq_str3  = sqs . qs2;   sq_str4  = sqs . qs3;
  sq_str5  = sqs . qs4;   sq_str6  = sqs . qs5;   sq_str7  = sqs . qs6;
  sq_str8  = sqs . qs7;   sq_str9  = sqs . qs8;   sq_str10 = sqs . qs9;
  sq_str11 = sqs . qs10;  sq_str12 = sqs . qs11;  sq_str13 = sqs . qs12;
  sq_str14 = sqs . qs13;  sq_str15 = sqs . qs14;  sq_str16 = sqs . qs15;
  sq_str17 = sqs . qs16;  sq_str18 = sqs . qs17;  sq_str19 = sqs . qs18;
  sq_str20 = sqs . qs19;  sq_str21 = sqs . qs20;  sq_str22 = sqs . qs21;
  sq_str23 = sqs . qs22;  sq_str24 = sqs . qs23;  sq_str25 = sqs . qs24;
  sq_str26 = sqs . qs25;  sq_str27 = sqs . qs26;  sq_str28 = sqs . qs27;
  sq_str29 = sqs . qs28;
  single_quote_strs  = (
    sq_str1  | sq_str2  | sq_str3  | sq_str4  | sq_str5  |
    sq_str6  | sq_str7  | sq_str8  | sq_str9  | sq_str10 |
    sq_str11 | sq_str12 | sq_str13 | sq_str14 | sq_str15 |
    sq_str16 | sq_str17 | sq_str18 | sq_str19 | sq_str20 |
    sq_str21 | sq_str22 | sq_str23 | sq_str24 | sq_str25 |
    sq_str26 | sq_str27 | sq_str28 | sq_str29
  );

  # NASTY mess for double quote strings
  # (currently we don't care abt interpolation, cos it is not a good
  # practice to put complicated stuff (eg. proc) within interpolation)
  dqs      = ('%Q' | '%W' | '%' | '%r' | '%x');
#  dq_str1  = '"' . (^'"' | '\"')? . '"';
#  dq_str2  = '`' . (^'`' | '\`')? . '`';
#  dq_str3  = '/' . (^'/' | '\/')? . '/';
  dq_str1  = '"' . [^\"]* . '"';
  dq_str2  = '`' . [^\`]* . '`';
  dq_str3  = '/' . [^\/]* . '/';
  dq_str4  = dqs . qs1;   dq_str5  = dqs . qs2;   dq_str6  = dqs . qs3;
  dq_str7  = dqs . qs4;   dq_str8  = dqs . qs5;   dq_str9  = dqs . qs6;
  dq_str10 = dqs . qs7;   dq_str11 = dqs . qs8;   dq_str12 = dqs . qs9;
  dq_str13 = dqs . qs10;  dq_str14 = dqs . qs11;  dq_str15 = dqs . qs12;
  dq_str16 = dqs . qs13;  dq_str17 = dqs . qs14;  dq_str18 = dqs . qs15;
  dq_str19 = dqs . qs16;  dq_str20 = dqs . qs17;  dq_str21 = dqs . qs18;
  dq_str22 = dqs . qs19;  dq_str23 = dqs . qs20;  dq_str24 = dqs . qs21;
  dq_str25 = dqs . qs22;  dq_str26 = dqs . qs23;  dq_str27 = dqs . qs24;
  dq_str28 = dqs . qs25;  dq_str29 = dqs . qs26;  dq_str30 = dqs . qs27;
  dq_str31 = dqs . qs28;
  double_quote_strs  = (
    dq_str1  | dq_str2  | dq_str3  | dq_str4  | dq_str5  |
    dq_str6  | dq_str7  | dq_str8  | dq_str9  | dq_str10 |
    dq_str11 | dq_str12 | dq_str13 | dq_str14 | dq_str15 |
    dq_str16 | dq_str17 | dq_str18 | dq_str19 | dq_str20 |
    dq_str21 | dq_str22 | dq_str23 | dq_str24 | dq_str25 |
    dq_str26 | dq_str27 | dq_str28 | dq_str29 | dq_str30 |
    dq_str31
  );

  # NASTY mess for double quote strings (w interpolation)

  main := |*

    do_block_start   => { push(k = :do_block_start, ts, te); increment_counter(k, :do_end) };
    do_block_end     => { push(k = :do_block_end, ts, te); decrement_counter(k, :do_end) };
    do_block_nstart1 => { push(k = :do_block_nstart1, ts, te); increment_counter(k, :do_end) };
    do_block_nstart2 => { push(k = :do_block_nstart2, ts, te); increment_counter(k, :do_end) };

    brace_block_start => { push(k = :brace_block_start, ts, te); increment_counter(k, :brace) };
    brace_block_end => { push(k = :brace_block_end, ts, te); decrement_counter(k, :brace) };

    modifier => { push(:any, ts, te) };
    lbrace   => { push(:any, ts, te) };
    rbrace   => { push(:any, ts, te) };
    lparen   => { push(:any, ts, te) };
    rparen   => { push(:any, ts, te) };
    smcolon  => { push(:any, ts, te) };
    newline  => { push(:any, ts, te); increment_line };
    ^alnum   => { push(:any, ts, te) };
    lvar     => { push(:meth, ts, te) };
    ovars    => { push(:any, ts, te) };
    symbol   => { push(:any, ts, te) };
    assoc    => { push(:assoc, ts, te); fix_counter_false_start(:brace) };
    label    => { push(:label, ts, te); fix_counter_false_start(:brace) };

    single_quote_strs => { push(:any, ts, te) };
    double_quote_strs => { push(:any, ts, te) };

    comments => { push(:comment, ts, te); increment_line };
    (' '+)   => { push(:any, ts, te) };
    any      => { push(:any, ts, te) };
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

#
# @@@@@@@@ @@@@@@@ @@@@@@@ @@@@@@@@ @@@@@@@
#    @@    @@      @@         @@    @@
#    @@    @@@@@@  @@@@@@@    @@    @@@@@@@
#    @@    @@           @@    @@         @@
#    @@    @@@@@@@ @@@@@@@    @@    @@@@@@@
#

if $0 == __FILE__
  require 'rubygems'
  require 'bacon'
  Bacon.summary_on_exit

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
      process(%{
        hello # blah
        world
      }).should.include("# blah\n")
    end

    should 'handle =begin ... =end' do
      process(%{
        hello
=begin aa
bb
=end cc
        world
        }).should.include(%{
=begin aa
bb
=end cc
})
    end

  end

end
