require File.join(File.dirname(__FILE__), 'scanner', 'extensions')

module Sourcify
  module Proc
    module Scanner #:nodoc:all

%%{
  machine proc_scanner;

  kw_class = 'class';

  const   = upper . (alnum | '_')*;
  var     = (lower | '_') . (alnum | '_')*;

  newline = '\n';
  ospaces = ' '*;
  mspaces = ' '+;

  ## One-liner comment
  per_line_comment := |*
    ^newline* => {
      push(:comment, ts.pred, te)
      fgoto main;
    };
  *|;

  ## Block comment
  block_comment := |*
    any* . newline . '=end' . ospaces . ^newline* => {
      unless push_comment(ts, te)
        fgoto main;
      end
    };
  *|;

  ## Heredoc
  heredoc := |*
    ^newline* . newline . ospaces . ^newline+ => {
      unless push_heredoc(ts, te)
        fgoto main;
      end
    };
  *|;

  ## Double quote string
  double_quote_str := |*
    delimiter = [\~\`\!\@\#\$\%\^\&\*\)\-\_\+\=\}\]\:\;\'\"\>\,\.\?\/\|\\];
    (^delimiter* . delimiter) -- ('\\' . delimiter) => {
      unless push_dstring(ts, te)
        fgoto main;
      end
    };
  *|;

  ## Main
  main := |*

    ## Singleton class
    kw_class . ospaces . '<<' . ospaces . ^newline+ => {
      push(:sclass, ts, te);
      increment_counter(1, :do_end)
    };

    ## Per line comment
    '#' => {
      fgoto per_line_comment;
    };

    ## Block comment
    newline . '=begin' . ospaces . (ospaces . ^newline+)* . newline => {
      push_comment(ts, te)
      increment_lineno
      fgoto block_comment;
    };

    ## Heredoc
    ('<<' | '<<-') . ["']? . (const | var) . ["']? . newline => {
      push_heredoc(ts, te)
      increment_lineno
      fgoto heredoc;
    };

    ## Single quote strings
    sqs1  = "'" . ([^\']* | ([^\']*[\\][\'][^\']*)*) . "'";
    sqs2  = '~' . ([^\~]* | ([^\~]*[\\][\~][^\~]*)*) . '~';
    sqs3  = '`' . ([^\`]* | ([^\`]*[\\][\`][^\`]*)*) . '`';
    sqs4  = '!' . ([^\!]* | ([^\!]*[\\][\!][^\!]*)*) . '!';
    sqs5  = '@' . ([^\@]* | ([^\@]*[\\][\@][^\@]*)*) . '@';
    sqs6  = '#' . ([^\#]* | ([^\#]*[\\][\#][^\#]*)*) . '#';
    sqs7  = '$' . ([^\$]* | ([^\$]*[\\][\$][^\$]*)*) . '$';
    sqs8  = '%' . ([^\%]* | ([^\%]*[\\][\%][^\%]*)*) . '%';
    sqs9  = '^' . ([^\^]* | ([^\^]*[\\][\^][^\^]*)*) . '^';
    sqs10 = '&' . ([^\&]* | ([^\&]*[\\][\&][^\&]*)*) . '&';
    sqs11 = '*' . ([^\*]* | ([^\*]*[\\][\*][^\*]*)*) . '*';
    sqs12 = '-' . ([^\-]* | ([^\-]*[\\][\-][^\-]*)*) . '-';
    sqs13 = '_' . ([^\_]* | ([^\_]*[\\][\_][^\_]*)*) . '_';
    sqs14 = '+' . ([^\+]* | ([^\+]*[\\][\+][^\+]*)*) . '+';
    sqs15 = '=' . ([^\=]* | ([^\=]*[\\][\=][^\=]*)*) . '=';
    sqs16 = '<' . ([^\>]* | ([^\>]*[\\][\>][^\>]*)*) . '>';
    sqs17 = '|' . ([^\|]* | ([^\|]*[\\][\|][^\|]*)*) . '|';
    sqs18 = ':' . ([^\:]* | ([^\:]*[\\][\:][^\:]*)*) . ':';
    sqs19 = ';' . ([^\;]* | ([^\;]*[\\][\;][^\;]*)*) . ';';
    sqs20 = '"' . ([^\"]* | ([^\"]*[\\][\"][^\"]*)*) . '"';
    sqs21 = ',' . ([^\,]* | ([^\,]*[\\][\,][^\,]*)*) . ',';
    sqs22 = '.' . ([^\.]* | ([^\.]*[\\][\.][^\.]*)*) . '.';
    sqs23 = '?' . ([^\?]* | ([^\?]*[\\][\?][^\?]*)*) . '?';
    sqs24 = '/' . ([^\/]* | ([^\/]*[\\][\/][^\/]*)*) . '/';
    sqs25 = '{' . ([^\}]* | ([^\}]*[\\][\}][^\}]*)*) . '}';
    sqs26 = '[' . ([^\]]* | ([^\]]*[\\][\]][^\]]*)*) . ']';
    sqs27 = '(' . ([^\)]* | ([^\)]*[\\][\)][^\)]*)*) . ')';
    sqs28 = '\\' . ([^\\]* | ([^\)]*[\\][\\][^\\]*)*) . '\\';

    sqm = ('%q' | '%w'); (
      sqs1        | sqm . sqs1  | sqm . sqs2  | sqm . sqs3  | sqm . sqs4  |
      sqm . sqs5  | sqm . sqs6  | sqm . sqs7  | sqm . sqs8  | sqm . sqs9  |
      sqm . sqs10 | sqm . sqs11 | sqm . sqs12 | sqm . sqs13 | sqm . sqs14 |
      sqm . sqs15 | sqm . sqs16 | sqm . sqs17 | sqm . sqs18 | sqm . sqs19 |
      sqm . sqs20 | sqm . sqs21 | sqm . sqs22 | sqm . sqs23 | sqm . sqs24 |
      sqm . sqs25 | sqm . sqs26 | sqm . sqs27 | sqm . sqs28
    ) => {
      push(:sstring, ts, te)
    };

    ## Double quote strings
    dqs1  = '"' . (([^\"]* | ([^\"]*[\\][\"][^\"]*)*) -- '#{') . ('"' | '#{');
    dqs2  = '`' . (([^\`]* | ([^\`]*[\\][\`][^\`]*)*) -- '#{') . ('`' | '#{');
    dqs3  = '/' . (([^\/]* | ([^\/]*[\\][\/][^\/]*)*) -- '#{') . ('/' | '#{');
    dqs4  = "'" . (([^\']* | ([^\']*[\\][\'][^\']*)*) -- '#{') . ("'" | '#{');
    dqs5  = '~' . (([^\~]* | ([^\~]*[\\][\~][^\~]*)*) -- '#{') . ('~' | '#{');
    dqs6  = '!' . (([^\!]* | ([^\!]*[\\][\!][^\!]*)*) -- '#{') . ('!' | '#{');
    dqs7  = '@' . (([^\@]* | ([^\@]*[\\][\@][^\@]*)*) -- '#{') . ('@' | '#{');
    dqs8  = '#' . (([^\#]* | ([^\#]*[\\][\#][^\#]*)*) -- '#{') . ('#' | '#{');
    dqs9  = '$' . (([^\$]* | ([^\$]*[\\][\$][^\$]*)*) -- '#{') . ('$' | '#{');
    dqs10 = '%' . (([^\%]* | ([^\%]*[\\][\%][^\%]*)*) -- '#{') . ('%' | '#{');
    dqs11 = '^' . (([^\^]* | ([^\^]*[\\][\^][^\^]*)*) -- '#{') . ('^' | '#{');
    dqs12 = '&' . (([^\&]* | ([^\&]*[\\][\&][^\&]*)*) -- '#{') . ('&' | '#{');
    dqs13 = '*' . (([^\*]* | ([^\*]*[\\][\*][^\*]*)*) -- '#{') . ('*' | '#{');
    dqs14 = '-' . (([^\-]* | ([^\-]*[\\][\-][^\-]*)*) -- '#{') . ('-' | '#{');
    dqs15 = '_' . (([^\_]* | ([^\_]*[\\][\_][^\_]*)*) -- '#{') . ('_' | '#{');
    dqs16 = '+' . (([^\+]* | ([^\+]*[\\][\+][^\+]*)*) -- '#{') . ('+' | '#{');
    dqs17 = '=' . (([^\=]* | ([^\=]*[\\][\=][^\=]*)*) -- '#{') . ('=' | '#{');
    dqs18 = '<' . (([^\>]* | ([^\>]*[\\][\>][^\>]*)*) -- '#{') . ('>' | '#{');
    dqs19 = '|' . (([^\|]* | ([^\|]*[\\][\|][^\|]*)*) -- '#{') . ('|' | '#{');
    dqs20 = ':' . (([^\:]* | ([^\:]*[\\][\:][^\:]*)*) -- '#{') . (':' | '#{');
    dqs21 = ';' . (([^\;]* | ([^\;]*[\\][\;][^\;]*)*) -- '#{') . (';' | '#{');
    dqs22 = ',' . (([^\,]* | ([^\,]*[\\][\,][^\,]*)*) -- '#{') . (',' | '#{');
    dqs23 = '.' . (([^\.]* | ([^\.]*[\\][\.][^\.]*)*) -- '#{') . ('.' | '#{');
    dqs24 = '?' . (([^\?]* | ([^\?]*[\\][\?][^\?]*)*) -- '#{') . ('?' | '#{');
    dqs25 = '{' . (([^\}]* | ([^\}]*[\\][\}][^\}]*)*) -- '#{') . ('}' | '#{');
    dqs26 = '[' . (([^\]]* | ([^\]]*[\\][\]][^\]]*)*) -- '#{') . (']' | '#{');
    dqs27 = '(' . (([^\)]* | ([^\)]*[\\][\)][^\)]*)*) -- '#{') . (')' | '#{');
    dqs28 = '\\' . (([^\\]* | ([^\\]*[\\][\\][^\\]*)*) -- '#{') . ('\\' | '#{');

    dqm = ('%Q' | '%W' | '%x' | '%r' | '%'); (
      dqs1        | dqs2        | dqs3        | dqm . dqs1  | dqm . dqs2  |
      dqm . dqs3  | dqm . dqs4  | dqm . dqs5  | dqm . dqs6  | dqm . dqs7  |
      dqm . dqs8  | dqm . dqs9  | dqm . dqs10 | dqm . dqs11 | dqm . dqs12 |
      dqm . dqs13 | dqm . dqs14 | dqm . dqs15 | dqm . dqs16 | dqm . dqs17 |
      dqm . dqs18 | dqm . dqs19 | dqm . dqs20 | dqm . dqs21 | dqm . dqs22 |
      dqm . dqs23 | dqm . dqs24 | dqm . dqs25 | dqm . dqs26 | dqm . dqs27 |
      dqm . dqs28
    ) => {
      if push_dstring(ts, te)
        fgoto double_quote_str;
      end
    };

    ## Misc
    var     => { push(:variable, ts, te) };
    const   => { push(:constant, ts, te) };
    newline => { push(:newline, ts, te); increment_lineno };
    mspaces => { push(:space, ts, te) };
    any     => { push(:any, ts, te) };

  *|;

#  vchar1    = lower | '_';
#  vchar2    = vchar1 | upper | digit;
#  cchar1    = upper;
#  cchar2    = cchar1 | vchar2;
#  var       = vchar1 . vchar2*;
#  const     = cchar1 . cchar2*;
#  symbol    = ':' . (var | const);
#
#  label     = (var | const) . ':';
#  assoc     = '=>';
#
#  lbrace    = '{';
#  rbrace    = '}';
#  lparen    = '(';
#  rparen    = ')';
#
#  newline   = '\n';
#  mspaces   = ' '+;
#  ospaces   = ' '*;
#  smcolon   = ';';
#
#  ## Keywords for do ... end matching
#
#  kw_do     = 'do';
#  kw_end    = 'end';
#  kw_begin  = 'begin';
#  kw_case   = 'case';
#  kw_while  = 'while';
#  kw_until  = 'until';
#  kw_for    = 'for';
#  kw_if     = 'if';
#  kw_unless = 'unless';
#  kw_class  = 'class';
#  kw_module = 'module';
#  kw_def    = 'def';
#
#  singleton_class  = kw_class . ospaces . '<<' . ospaces . ^space+;
#  modifier         = kw_if | kw_unless | kw_while | kw_until;
#  line_start_w_nl  = newline . ospaces;
#  line_start_wo_nl = (lparen | smcolon) . ospaces;
#
#  # NOTE:
#  # * 'm' ~> always consuming a matching 'end'
#  # * 'o' ~> may or may not be consuming a matching 'end'
#  kw_mblock = kw_begin | kw_case | kw_module | kw_def | kw_if | kw_unless | kw_class | singleton_class;
#  kw_oblock = kw_while | kw_until | kw_for;
#
#  do_block_start   = kw_do;
#  do_block_end     = kw_end;
#  do_block_mstart_w_nl  = line_start_w_nl . kw_mblock;
#  do_block_mstart_wo_nl = line_start_wo_nl . kw_mblock;
#  do_block_ostart_w_nl  = line_start_w_nl . kw_oblock;
#  do_block_ostart_wo_nl = line_start_wo_nl . kw_oblock;
#
#  ## COMMENTS
#  line_comment  = '#' . ^newline*;
#  block_comment = newline . '=begin' . ^newline* . newline . any* . newline . '=end' . ^newline* . newline;
#  comments      = (line_comment | block_comment);
#
#  ## STRINGS
#
#  # Heredoc requires more processing on scripting side, cos ragel doesn't
#  # support backreferencing, so we only catch the begin fragment here.
#  heredoc_start = ('<<' | '<<-') . (var | const) . newline;
#
#  # Single quote strings are pretty straight-forward, cos no embedding/interpolation
#  # support is required.
#  sqs1  = '~' . (zlen | [^\~]* | ([^\~]*[\\][\~][^\~]*)*) . '~';
#  sqs2  = '`' . (zlen | [^\`]* | ([^\`]*[\\][\`][^\`]*)*) . '`';
#  sqs3  = '!' . (zlen | [^\!]* | ([^\!]*[\\][\!][^\!]*)*) . '!';
#  sqs4  = '@' . (zlen | [^\@]* | ([^\@]*[\\][\@][^\@]*)*) . '@';
#  sqs5  = '#' . (zlen | [^\#]* | ([^\#]*[\\][\#][^\#]*)*) . '#';
#  sqs6  = '$' . (zlen | [^\$]* | ([^\$]*[\\][\$][^\$]*)*) . '$';
#  sqs7  = '%' . (zlen | [^\%]* | ([^\%]*[\\][\%][^\%]*)*) . '%';
#  sqs8  = '^' . (zlen | [^\^]* | ([^\^]*[\\][\^][^\^]*)*) . '^';
#  sqs9  = '&' . (zlen | [^\&]* | ([^\&]*[\\][\&][^\&]*)*) . '&';
#  sqs10 = '*' . (zlen | [^\*]* | ([^\*]*[\\][\*][^\*]*)*) . '*';
#  sqs11 = '-' . (zlen | [^\-]* | ([^\-]*[\\][\-][^\-]*)*) . '-';
#  sqs12 = '_' . (zlen | [^\_]* | ([^\_]*[\\][\_][^\_]*)*) . '_';
#  sqs13 = '+' . (zlen | [^\+]* | ([^\+]*[\\][\+][^\+]*)*) . '+';
#  sqs14 = '=' . (zlen | [^\=]* | ([^\=]*[\\][\=][^\=]*)*) . '=';
#  sqs15 = '<' . (zlen | [^\>]* | ([^\>]*[\\][\>][^\>]*)*) . '>';
#  sqs16 = '|' . (zlen | [^\|]* | ([^\|]*[\\][\|][^\|]*)*) . '|';
#  sqs17 = ':' . (zlen | [^\:]* | ([^\:]*[\\][\:][^\:]*)*) . ':';
#  sqs18 = ';' . (zlen | [^\;]* | ([^\;]*[\\][\;][^\;]*)*) . ';';
#  sqs19 = '"' . (zlen | [^\"]* | ([^\"]*[\\][\"][^\"]*)*) . '"';
#  sqs20 = "'" . (zlen | [^\']* | ([^\']*[\\][\'][^\']*)*) . "'";
#  sqs21 = ',' . (zlen | [^\,]* | ([^\,]*[\\][\,][^\,]*)*) . ',';
#  sqs22 = '.' . (zlen | [^\.]* | ([^\.]*[\\][\.][^\.]*)*) . '.';
#  sqs23 = '?' . (zlen | [^\?]* | ([^\?]*[\\][\?][^\?]*)*) . '?';
#  sqs24 = '/' . (zlen | [^\/]* | ([^\/]*[\\][\/][^\/]*)*) . '/';
#  sqs25 = '{' . (zlen | [^\}]* | ([^\}]*[\\][\}][^\}]*)*) . '}';
#  sqs26 = '[' . (zlen | [^\]]* | ([^\]]*[\\][\]][^\]]*)*) . ']';
#  sqs27 = '(' . (zlen | [^\)]* | ([^\)]*[\\][\)][^\)]*)*) . ')';
#  sqs28 = '\\' . (zlen | [^\\]* | ([^\)]*[\\][\\][^\\]*)*) . '\\';
#
#  sqsm     = ('%q' | '%w');
#  sq_str1  = sqs20;         sq_str2  = sqsm . sqs1;   sq_str3  = sqsm . sqs2;
#  sq_str4  = sqsm . sqs3;   sq_str5  = sqsm . sqs4;   sq_str6  = sqsm . sqs5;
#  sq_str7  = sqsm . sqs6;   sq_str8  = sqsm . sqs7;   sq_str9  = sqsm . sqs8;
#  sq_str10 = sqsm . sqs9;   sq_str11 = sqsm . sqs10;  sq_str12 = sqsm . sqs11;
#  sq_str13 = sqsm . sqs12;  sq_str14 = sqsm . sqs13;  sq_str15 = sqsm . sqs14;
#  sq_str16 = sqsm . sqs15;  sq_str17 = sqsm . sqs16;  sq_str18 = sqsm . sqs17;
#  sq_str19 = sqsm . sqs18;  sq_str20 = sqsm . sqs19;  sq_str21 = sqsm . sqs20;
#  sq_str22 = sqsm . sqs21;  sq_str23 = sqsm . sqs22;  sq_str24 = sqsm . sqs23;
#  sq_str25 = sqsm . sqs24;  sq_str26 = sqsm . sqs25;  sq_str27 = sqsm . sqs26;
#  sq_str28 = sqsm . sqs27;  sq_str29 = sqsm . sqs28;
#  single_quote_strs  = (
#    sq_str1  | sq_str2  | sq_str3  | sq_str4  | sq_str5  |
#    sq_str6  | sq_str7  | sq_str8  | sq_str9  | sq_str10 |
#    sq_str11 | sq_str12 | sq_str13 | sq_str14 | sq_str15 |
#    sq_str16 | sq_str17 | sq_str18 | sq_str19 | sq_str20 |
#    sq_str21 | sq_str22 | sq_str23 | sq_str24 | sq_str25 |
#    sq_str26 | sq_str27 | sq_str28 | sq_str29
#  );
#
#  # Double quote strings are more tedious to work with, because of
#  # embedding/interpolation issues.
#
#  dqsm     = ('%Q' | '%W' | '%' | '%r' | '%x');
#  dq_str1  = dqs19;         dq_str2  = dqs2;          dq_str3  = dqs24;
#  dq_str4  = dqsm . dqs1;   dq_str5  = dqsm . dqs2;   dq_str6  = dqsm . dqs3;
#  dq_str7  = dqsm . dqs4;   dq_str8  = dqsm . dqs5;   dq_str9  = dqsm . dqs6;
#  dq_str10 = dqsm . dqs7;   dq_str11 = dqsm . dqs8;   dq_str12 = dqsm . dqs9;
#  dq_str13 = dqsm . dqs10;  dq_str14 = dqsm . dqs11;  dq_str15 = dqsm . dqs12;
#  dq_str16 = dqsm . dqs13;  dq_str17 = dqsm . dqs14;  dq_str18 = dqsm . dqs15;
#  dq_str19 = dqsm . dqs16;  dq_str20 = dqsm . dqs17;  dq_str21 = dqsm . dqs18;
#  dq_str22 = dqsm . dqs19;  dq_str23 = dqsm . dqs20;  dq_str24 = dqsm . dqs21;
#  dq_str25 = dqsm . dqs22;  dq_str26 = dqsm . dqs23;  dq_str27 = dqsm . dqs24;
#  dq_str28 = dqsm . dqs25;  dq_str29 = dqsm . dqs26;  dq_str30 = dqsm . dqs27;
#  dq_str31 = dqsm . dqs28;
#  double_quote_strs  = (
#    dq_str1  | dq_str2  | dq_str3  | dq_str4  | dq_str5  |
#    dq_str6  | dq_str7  | dq_str8  | dq_str9  | dq_str10 |
#    dq_str11 | dq_str12 | dq_str13 | dq_str14 | dq_str15 |
#    dq_str16 | dq_str17 | dq_str18 | dq_str19 | dq_str20 |
#    dq_str21 | dq_str22 | dq_str23 | dq_str24 | dq_str25 |
#    dq_str26 | dq_str27 | dq_str28 | dq_str29 | dq_str30 |
#    dq_str31
#  );
#
#  main := |*
#
#    do_block_start => {
#      push(k = :do_block_start, ts, te)
#      increment_counter(k, :do_end)
#    };
#
#    do_block_end => {
#      push(k = :do_block_end, ts, te)
#      decrement_counter(k, :do_end)
#    };
#
#    do_block_mstart_wo_nl => {
#      push(k = :do_block_mstart, ts, te)
#      increment_counter(k, :do_end)
#    };
#
#    do_block_ostart_wo_nl => {
#      push(k = :do_block_ostart, ts, te);
#      increment_counter(k, :do_end)
#    };
#
#    do_block_mstart_w_nl => {
#      push(k = :do_block_mstart, ts, te)
#      increment_counter(k, :do_end)
#      increment_lineno
#    };
#
#    do_block_ostart_w_nl => {
#      push(k = :do_block_ostart, ts, te)
#      increment_counter(k, :do_end)
#      increment_lineno
#    };
#
#    lbrace => {
#      push(:lbrace, ts, te)
#      increment_counter(:brace_block_start, :brace)
#    };
#
#    rbrace => {
#      push(:rbrace, ts, te)
#      decrement_counter(:brace_block_end, :brace)
#    };
#
#    newline  => {
#      push(:newline, ts, te)
#      increment_lineno
#    };
#
#    assoc    => {
#      push(:assoc, ts, te)
#      fix_counter_false_start(:brace)
#    };
#
#    label    => {
#      push(:label, ts, te)
#      fix_counter_false_start(:brace)
#    };
#
#    heredoc_start => {
#      push(:heredoc_start, ts, te)
#      increment_lineno
#    };
#
#    single_quote_strs => { push(:squote_str, ts, te) };
#    double_quote_strs => { push(:dquote_str, ts, te) };
#
#    modifier => { push(:modifier, ts, te) };
#    lparen   => { push(:lparen, ts, te) };
#    rparen   => { push(:rparen, ts, te) };
#    smcolon  => { push(:smcolon, ts, te) };
#    var      => { push(:var, ts, te) };
#    const    => { push(:const, ts, te) };
#    symbol   => { push(:symbol, ts, te) };
#    comments => { push(:comment, ts, te) };
#
#    mspaces  => { push(:spaces, ts, te) };
#    any      => { push(:any, ts, te) };
#  *|;

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
