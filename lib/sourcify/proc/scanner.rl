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
  keywords      = (
    kw_do | kw_end | kw_begin | kw_case | kw_while | kw_until |
    kw_for | kw_if | kw_unless | kw_class | kw_module | kw_def
  );

  lbrace        = '{';
  rbrace        = '}';
  lparen        = '(';
  rparen        = ')';

  lvar          = [a-z_][a-zA-Z0-9_]* - keywords;
  ovars         = ('@' | '@@' | '$') . lvar;
  symbol        = ':' . (lvar | ovars);
  label         = lvar . ':';
  constant      = [A-Z_][a-zA-Z0-9_]*;
  newline       = '\n';

  assoc         = '=>';
  assgn         = '=';
  smcolon       = ';';
  spaces        = ' '*;
  line_start1   = newline . spaces;
  line_start2   = (smcolon | lparen) . spaces;
  line_start    = (line_start1 | line_start2);
  modifier      = (kw_if | kw_unless | kw_while | kw_until);
  squote        = "'";
  dquote        = '"';

  line_comment  = '#' . ^newline* . newline;
  block_comment = newline . '=begin' . ^newline* . newline . any* . newline . '=end' . ^newline* . newline;
  comments      = (line_comment | block_comment);

  cfrag1        = '<<' . spaces . (^spaces & ^newline)+;
  cfrag2        = constant . spaces . '<' . spaces . constant;
  cfrag3        = constant;
  declare_class = kw_class . spaces . (cfrag1 | cfrag2 | cfrag3);

  do_block_start    = kw_do;
  do_block_end      = kw_end;
  do_block_nstart1a = line_start1 . (declare_class | kw_if | kw_unless | kw_module | kw_def | kw_begin | kw_case);
  do_block_nstart1b = line_start2 . (declare_class | kw_if | kw_unless | kw_module | kw_def | kw_begin | kw_case);
  do_block_nstart2a = line_start1 . (kw_while | kw_until | kw_for);
  do_block_nstart2b = line_start2 . (kw_while | kw_until | kw_for);

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

#  qs1  = '~' . ^'~'* . '~'; qs2  = '`' . ^'`'* . '`';
#  qs3  = '!' . ^'!'* . '!';  qs4  = '@' . ^'@'* . '@';
#  qs5  = '#' . ^'#'* . '#';  qs6  = '$' . ^'$'* . '$';
#  qs7  = '%' . ^'%'* . '%';  qs8  = '^' . ^'^'* . '^';
#  qs9  = '&' . ^'&'* . '&';  qs10 = '*' . ^'*'* . '*';
#  qs11 = '-' . ^'-'* . '-';  qs12 = '_' . ^'_'* . '_';
#  qs13 = '+' . ^'+'* . '+';  qs14 = '=' . ^'='* . '=';
#  qs15 = '<' . ^'>'* . '>';  qs16 = '|' . ^'|'* . '|';
#  qs17 = ':' . ^':'* . ':';  qs18 = ';' . ^';'* . ';';
#  qs19 = '"' . ^'"'* . '"';  qs20 = "'" . ^"'"* . "'";
#  qs21 = ',' . ^','* . ',';  qs22 = '.' . ^'.'* . '.';
#  qs23 = '?' . ^'?'* . '?';  qs24 = '/' . ^'/'* . '/';
#  qs25 = '{' . ^'}'* . '}';  qs26 = '[' . ^']'* . ']';
#  qs27 = '(' . ^')'* . ')';  qs28 = '\\' . ^'\\'* . '\\';

  # NASTY mess for string delimiters
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

  # NASTY mess for single quoted strings
  sqs      = ('%q' | '%w');
  sq_str1  = qs20;
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

  # Heredoc. Currently, disabling keywords as heredoc tag can potentially be a bug, since
  # ruby allows keyword as heredoc tag, though it is a bad practice to do it. Anyway, we'll
  # fix this if there is really a significant number of people using keywords as heredoc tag.
  hchar1         = [A-Za-z\_];
  hchar2         = [A-Za-z0-9\_];
  heredoc_tag    = (hchar1 . hchar2{,1} | (hchar1 . hchar2{2}) - keywords | hchar1 . hchar2{3,});
  heredoc_begin  = ('<<' | '<<-') . heredoc_tag . newline;
  heredoc_end    = newline . spaces . heredoc_tag . newline;

  main := |*

    do_block_start    => { push(k = :do_block_start, ts, te); increment_counter(k, :do_end) };
    do_block_end      => { push(k = :do_block_end, ts, te); decrement_counter(k, :do_end) };
    do_block_nstart1b => { push(k = :do_block_nstart1, ts, te); increment_counter(k, :do_end) };
    do_block_nstart2b => { push(k = :do_block_nstart2, ts, te); increment_counter(k, :do_end) };

    do_block_nstart1a => {
      push(k = :do_block_nstart1, ts, te)
      increment_counter(k, :do_end)
      increment_line
    };

    do_block_nstart2a => {
      push(k = :do_block_nstart2, ts, te)
      increment_counter(k, :do_end)
      increment_line
    };

    lbrace => { push(:lbrace, ts, te); increment_counter(:brace_block_start, :brace) };
    rbrace => { push(:rbrace, ts, te); decrement_counter(:brace_block_end, :brace) };

    modifier => { push(:modifier, ts, te) };
    lparen   => { push(:lparen, ts, te) };
    rparen   => { push(:rparen, ts, te) };
    smcolon  => { push(:smcolon, ts, te) };
    newline  => { push(:newline, ts, te); increment_line };
    lvar     => { push(:lvar, ts, te) };
    ovars    => { push(:ovars, ts, te) };
    symbol   => { push(:symbol, ts, te) };
    assoc    => { push(:assoc, ts, te); fix_counter_false_start(:brace) };
    label    => { push(:label, ts, te); fix_counter_false_start(:brace) };

    single_quote_strs => { push(:squote_str, ts, te) };
    double_quote_strs => { push(:dquote_str, ts, te) };
    heredoc_begin     => { push(:heredoc_begin, ts, te); increment_line };
    heredoc_end       => { push(:heredoc_end, ts, te); increment_line };

    #comments => { push(:comment, ts, te); increment_line };
    (' '+)   => { push(:spaces, ts, te) };
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
