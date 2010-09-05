curr_dir = File.dirname(__FILE__)
require File.join(curr_dir, 'heredoc')
require File.join(curr_dir, 'counter')

module Sourcify
  module Proc
    module Scanner #:nodoc:all
      module Extensions

        class Escape < Exception; end

        def process(data)
          begin
            puts '', data
            @results, @data = [], data.unpack("c*")
            reset_attributes
            execute!
          rescue Escape
            @results
          end
        end

        def push(key, ts, te)
          data = data_frag(ts .. te.pred)
          if @heredoc
            push_heredoc_content(data, data_frag(te .. te))
          elsif respond_to?(dpush = :"push_#{key}")
            send(dpush, data)
          else
            @keys << key
            @tokens << data
          end
        end

        def data_frag(range)
          @data[range].pack('c*')
        end

        def push_label(data)
          # NOTE: 1.9.* supports label key, which RubyParser cannot handle, thus
          # conversion is needed.
          @tokens << data.sub(/^(.*)\:$/, ':\1') << ' ' << '=>'
          @keys << :symbol << :spaces << :assoc
        end

        def push_heredoc_start(data)
          # NOTE: Ragel doesn't support backreferencing, that's why we need to take
          # special care for heredoc
          m = data.match(/\<\<(\-?)(\w+)\s*$/)[1..2]
          @heredoc = Heredoc.new(@tokens.size, m[1], !m[0].empty?)
          @heredoc.contents << data
        end

        def push_heredoc_content(data, next_token)
          @heredoc.contents << data
          if @heredoc.ending?(next_token)
            @tokens << @heredoc.contents.join
            @keys << :heredoc
            @heredoc = nil
          end
        end

        def increment_line
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
          when :do_block_nstart1
            @do_end_counter.increment if @do_end_counter.started?
          when :do_block_nstart2
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
