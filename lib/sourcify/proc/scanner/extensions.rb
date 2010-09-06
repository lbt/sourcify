curr_dir = File.dirname(__FILE__)
require File.join(curr_dir, 'heredoc')
require File.join(curr_dir, 'comment')
require File.join(curr_dir, 'counter')

module Sourcify
  module Proc
    module Scanner #:nodoc:all
      module Extensions

        class Escape < Exception; end

        def process(data)
          begin
            @results, @data = [], data.unpack("c*")
            reset_attributes
            execute!
          rescue Escape
            @results
          end
        end

        def push(key, ts, te)
          data = data_frag(ts .. te.pred)
          @keys << key
          @tokens << data_frag(ts .. te.pred)
        end

        def data_frag(range)
          @data[range].pack('c*')
        end

        def push_comment(ts, te)
          data = data_frag(ts .. te.pred)
          if @comment.nil?
            @comment = Comment.new
            @comment << data
          else
            @comment << data
            return true unless @comment.closed?(data_frag(te .. te))
            @tokens << @comment.to_s
            @keys << :comment
            @comment = nil
          end
        end

        def push_heredoc(ts, te)
          data = data_frag(ts .. te.pred)
          if @heredoc.nil?
            indented, tag = data.match(/\<\<(\-?)['"]?(\w+)['"]?$/)[1..3]
            @heredoc = Heredoc.new(tag, !indented.empty?)
            @heredoc << data
          else
            @heredoc << data
            return true unless @heredoc.closed?(data_frag(te .. te))
            @tokens << @heredoc.to_s
            @keys << :heredoc
            @heredoc = nil
          end
        end

        def push_label(data)
          # NOTE: 1.9.* supports label key, which RubyParser cannot handle, thus
          # conversion is needed.
          @tokens << data.sub(/^(.*)\:$/, ':\1') << ' ' << '=>'
          @keys << :symbol << :spaces << :assoc
        end

        def increment_lineno
          puts '', 'increment_line (before) ... %s' % @lineno
          @lineno += 1
          puts '', 'increment_line (after) ... %s' % @lineno
          raise Escape unless @results.empty?
        end

        def increment_counter(type, key)
          send(:"increment_#{key}_counter", type) unless @heredoc
        end

        def decrement_counter(type, key)
          send(:"decrement_#{key}_counter") unless @heredoc
        end

        def increment_do_end_counter(type)
          return if @brace_counter.started?
          case type
          when :do_block_mstart
            @do_end_counter.increment if @do_end_counter.started?
          when :do_block_ostart
            @do_end_counter.increment(0..1) if @do_end_counter.started?
          when :do_block_start
            offset_attributes unless @do_end_counter.started?
            @do_end_counter.increment
          end
        end

        def decrement_do_end_counter
          return unless @do_end_counter.started?
          puts '', 'before decrement_do_end_counter = %s, %s' % @do_end_counter.counts
          @do_end_counter.decrement
          puts '', 'after decrement_do_end_counter = %s, %s' % @do_end_counter.counts
          construct_result_code if @do_end_counter.balanced?
        end

        def increment_brace_counter(type)
          return if @do_end_counter.started?
          offset_attributes unless @brace_counter.started?
          @brace_counter.increment
        end

        def decrement_brace_counter
          return unless @brace_counter.started?
          @brace_counter.decrement
          construct_result_code if @brace_counter.balanced?
        end

        def fix_counter_false_start(key)
          if instance_variable_get(:"@#{key}_counter").just_started?
            reset_attributes
          end
        end

        def construct_result_code
          begin
            code = 'proc ' + @tokens.join
            puts '', code 
            eval(code) # TODO: is there a better way to check for SyntaxError ?
            puts '', code
            @results << code
            raise Escape unless @lineno == 1
            reset_attributes
          rescue SyntaxError
          end
        end

        def reset_attributes
          @tokens = []
          @keys = []
          @lineno = 1
          @heredoc = nil
          @do_end_counter = Counter.new
          @brace_counter = Counter.new
        end

        def offset_attributes
          @lineno = 1 # Fixing JRuby's lineno bug (see http://jira.codehaus.org/browse/JRUBY-5014)
          unless @tokens.empty?
            [@tokens, @keys].each do |var|
              last = var[-1]
              var.clear
              var << last
            end
          end
        end

      end
    end
  end
end
