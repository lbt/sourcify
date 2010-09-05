require File.join(File.dirname(__FILE__), 'scanner', 'extensions')

module Sourcify
  module Proc
    module Scanner #:nodoc:all

%%{
  machine proc;

  vchar1    = lower | '_';
  vchar2    = vchar1 | upper | digit;
  cchar1    = upper;
  cchar2    = cchar1 | vchar2;
  var       = vchar1 . vchar2*;
  const     = cchar1 . cchar2*;
  symbol    = ':' . (var | const);

  label     = (var | const) . ':';
  assoc     = '=>';

  lbrace    = '{';
  rbrace    = '}';
  lparen    = '(';
  rparen    = ')';

  newline   = '\n';
  mspaces   = ' '+;
  ospaces   = ' '*;
  smcolon   = ';';

  ## Keywords for do ... end matching

  kw_do     = 'do';
  kw_end    = 'end';
  kw_begin  = 'begin';
  kw_case   = 'case';
  kw_while  = 'while';
  kw_until  = 'until';
  kw_for    = 'for';
  kw_if     = 'if';
  kw_unless = 'unless';
  kw_class  = 'class';
  kw_module = 'module';
  kw_def    = 'def';

  singleton_class  = kw_class . ospaces . '<<' . ospaces . ^space+;
  modifier         = kw_if | kw_unless | kw_while | kw_until;
  line_start_w_nl  = newline . ospaces;
  line_start_wo_nl = (lparen | smcolon) . ospaces;

  # NOTE:
  # * 'm' ~> always consuming a matching 'end'
  # * 'o' ~> may or may not be consuming a matching 'end'
  kw_mblock = kw_begin | kw_case | kw_module | kw_def | kw_if | kw_unless | kw_class | singleton_class;
  kw_oblock = kw_while | kw_until | kw_for;

  do_block_start   = kw_do;
  do_block_end     = kw_end;
  do_block_mstart_w_nl  = line_start_w_nl . kw_mblock;
  do_block_mstart_wo_nl = line_start_wo_nl . kw_mblock;
  do_block_ostart_w_nl  = line_start_w_nl . kw_oblock;
  do_block_ostart_wo_nl = line_start_wo_nl . kw_oblock;

  ## COMMENTS
  line_comment  = '#' . ^newline*;
  block_comment = newline . '=begin' . ^newline* . newline . any* . newline . '=end' . ^newline* . newline;
  comments      = (line_comment | block_comment);

  ## STRINGS

  # Heredoc requires more processing on scripting side, cos ragel doesn't
  # support backreferencing, so we only catch the begin fragment here.
  heredoc_start = ('<<' | '<<-') . (var | const) . newline;

  # String delimiters
  qs1  = '~' . (zlen | [^\~]* | ([^\~]*[\\][\~][^\~]*)*) . '~';
  qs2  = '`' . (zlen | [^\`]* | ([^\`]*[\\][\`][^\`]*)*) . '`';
  qs3  = '!' . (zlen | [^\!]* | ([^\!]*[\\][\!][^\!]*)*) . '!';
  qs4  = '@' . (zlen | [^\@]* | ([^\@]*[\\][\@][^\@]*)*) . '@';
  qs5  = '#' . (zlen | [^\#]* | ([^\#]*[\\][\#][^\#]*)*) . '#';
  qs6  = '$' . (zlen | [^\$]* | ([^\$]*[\\][\$][^\$]*)*) . '$';
  qs7  = '%' . (zlen | [^\%]* | ([^\%]*[\\][\%][^\%]*)*) . '%';
  qs8  = '^' . (zlen | [^\^]* | ([^\^]*[\\][\^][^\^]*)*) . '^';
  qs9  = '&' . (zlen | [^\&]* | ([^\&]*[\\][\&][^\&]*)*) . '&';
  qs10 = '*' . (zlen | [^\*]* | ([^\*]*[\\][\*][^\*]*)*) . '*';
  qs11 = '-' . (zlen | [^\-]* | ([^\-]*[\\][\-][^\-]*)*) . '-';
  qs12 = '_' . (zlen | [^\_]* | ([^\_]*[\\][\_][^\_]*)*) . '_';
  qs13 = '+' . (zlen | [^\+]* | ([^\+]*[\\][\+][^\+]*)*) . '+';
  qs14 = '=' . (zlen | [^\=]* | ([^\=]*[\\][\=][^\=]*)*) . '=';
  qs15 = '<' . (zlen | [^\>]* | ([^\>]*[\\][\>][^\>]*)*) . '>';
  qs16 = '|' . (zlen | [^\|]* | ([^\|]*[\\][\|][^\|]*)*) . '|';
  qs17 = ':' . (zlen | [^\:]* | ([^\:]*[\\][\:][^\:]*)*) . ':';
  qs18 = ';' . (zlen | [^\;]* | ([^\;]*[\\][\;][^\;]*)*) . ';';
  qs19 = '"' . (zlen | [^\"]* | ([^\"]*[\\][\"][^\"]*)*) . '"';
  qs20 = "'" . (zlen | [^\']* | ([^\']*[\\][\'][^\']*)*) . "'";
  qs21 = ',' . (zlen | [^\,]* | ([^\,]*[\\][\,][^\,]*)*) . ',';
  qs22 = '.' . (zlen | [^\.]* | ([^\.]*[\\][\.][^\.]*)*) . '.';
  qs23 = '?' . (zlen | [^\?]* | ([^\?]*[\\][\?][^\?]*)*) . '?';
  qs24 = '/' . (zlen | [^\/]* | ([^\/]*[\\][\/][^\/]*)*) . '/';
  qs25 = '{' . (zlen | [^\}]* | ([^\}]*[\\][\}][^\}]*)*) . '}';
  qs26 = '[' . (zlen | [^\]]* | ([^\]]*[\\][\]][^\]]*)*) . ']';
  qs27 = '(' . (zlen | [^\)]* | ([^\)]*[\\][\)][^\)]*)*) . ')';
  qs28 = '\\' . (zlen | [^\\]* | ([^\)]*[\\][\\][^\\]*)*) . '\\';

  # Single quote strings are pretty straight-forward, cos no embedding/interpolation
  # support is required.
  sqs      = ('%q' | '%w');
  sq_str1  = qs20;        sq_str2  = sqs . qs1;   sq_str3  = sqs . qs2;
  sq_str4  = sqs . qs3;   sq_str5  = sqs . qs4;   sq_str6  = sqs . qs5;
  sq_str7  = sqs . qs6;   sq_str8  = sqs . qs7;   sq_str9  = sqs . qs8;
  sq_str10 = sqs . qs9;   sq_str11 = sqs . qs10;  sq_str12 = sqs . qs11;
  sq_str13 = sqs . qs12;  sq_str14 = sqs . qs13;  sq_str15 = sqs . qs14;
  sq_str16 = sqs . qs15;  sq_str17 = sqs . qs16;  sq_str18 = sqs . qs17;
  sq_str19 = sqs . qs18;  sq_str20 = sqs . qs19;  sq_str21 = sqs . qs20;
  sq_str22 = sqs . qs21;  sq_str23 = sqs . qs22;  sq_str24 = sqs . qs23;
  sq_str25 = sqs . qs24;  sq_str26 = sqs . qs25;  sq_str27 = sqs . qs26;
  sq_str28 = sqs . qs27;  sq_str29 = sqs . qs28;
  single_quote_strs  = (
    sq_str1  | sq_str2  | sq_str3  | sq_str4  | sq_str5  |
    sq_str6  | sq_str7  | sq_str8  | sq_str9  | sq_str10 |
    sq_str11 | sq_str12 | sq_str13 | sq_str14 | sq_str15 |
    sq_str16 | sq_str17 | sq_str18 | sq_str19 | sq_str20 |
    sq_str21 | sq_str22 | sq_str23 | sq_str24 | sq_str25 |
    sq_str26 | sq_str27 | sq_str28 | sq_str29
  );

  # Double quote strings are more tedious to work with, because of
  # embedding/interpolation issues.
  dqs      = ('%Q' | '%W' | '%' | '%r' | '%x');
  dq_str1  = qs19;        dq_str2  = qs2;         dq_str3  = qs24;
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

  main := |*

    do_block_start => {
      push(k = :do_block_start, ts, te)
      increment_counter(k, :do_end)
    };

    do_block_end => {
      push(k = :do_block_end, ts, te)
      decrement_counter(k, :do_end)
    };

    do_block_mstart_wo_nl => {
      push(k = :do_block_mstart, ts, te)
      increment_counter(k, :do_end)
    };

    do_block_ostart_wo_nl => {
      push(k = :do_block_ostart, ts, te);
      increment_counter(k, :do_end)
    };

    do_block_mstart_w_nl => {
      push(k = :do_block_mstart, ts, te)
      increment_counter(k, :do_end)
      increment_line
    };

    do_block_ostart_w_nl => {
      push(k = :do_block_ostart, ts, te)
      increment_counter(k, :do_end)
      increment_line
    };

    lbrace => {
      push(:lbrace, ts, te)
      increment_counter(:brace_block_start, :brace)
    };

    rbrace => {
      push(:rbrace, ts, te)
      decrement_counter(:brace_block_end, :brace)
    };

    newline  => {
      push(:newline, ts, te)
      increment_line
    };

    assoc    => {
      push(:assoc, ts, te)
      fix_counter_false_start(:brace)
    };

    label    => {
      push(:label, ts, te)
      fix_counter_false_start(:brace)
    };

    heredoc_start => {
      push(:heredoc_start, ts, te)
      increment_line
    };

    single_quote_strs => { push(:squote_str, ts, te) };
    double_quote_strs => { push(:dquote_str, ts, te) };

    modifier => { push(:modifier, ts, te) };
    lparen   => { push(:lparen, ts, te) };
    rparen   => { push(:rparen, ts, te) };
    smcolon  => { push(:smcolon, ts, te) };
    var      => { push(:var, ts, te) };
    const    => { push(:const, ts, te) };
    symbol   => { push(:symbol, ts, te) };
    comments => { push(:comment, ts, te) };

    mspaces  => { push(:spaces, ts, te) };
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
