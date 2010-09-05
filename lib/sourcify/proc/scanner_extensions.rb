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
          data = @data[ts .. te.pred].pack('c*')
          begin
            key = :lvar if key == :heredoc_end && @heredoc.nil?
            send(:"push_#{key}", data)
          rescue
            @keys << key
            @tokens << data
          end
        end

        def push_label(data)
          # NOTE: 1.9.* supports label key, which RubyParser cannot handle, thus
          # conversion is needed.
          @tokens << data.sub(/^(.*)\:$/, ':\1') << ' ' << '=>'
          @keys << :symbol << :any << :assoc
        end

        def push_heredoc_begin(data)
          # NOTE: Ragel doesn't support back-referencing, that's why we need to take
          # special care for heredoc
          m = data.match(/\<\<(\-?)(\w+)\s*$/)[1..2]
          increment_line
          @heredoc = {:begin => @tokens.size, :tag => m[1], :indent => !m[0].empty?}
          @tokens << data
          @keys << :any
        end

        def push_heredoc_end(data)
          indent, tag, index = [:indent, :tag, :begin].map{|k| @heredoc[k] } rescue nil
          if (indent && data.strip == tag) or (!indent && data == "\n#{tag}\n")
            @heredoc = nil
            @keys.slice!(index .. -1)
            @tokens << (@tokens.slice!(index .. -1) << data).join
            @keys << :heredoc
          else
            @keys << :heredoc_false_end
            @tokens << data
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

        class Counter

          attr_reader :counts

          def initialize
            @counts = [0,0]
          end

          def started?
            @counts.any?(&:nonzero?)
          end

          def just_started?
            @counts.any?{|count| count == 1 }
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
