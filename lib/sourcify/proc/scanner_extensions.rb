module Sourcify
  module Proc
    module Scanner #:nodoc:all
      module Extensions

        class Escape < Exception; end

        def process(data)
          require 'pp'
          begin
            @results, @data = [], data.unpack("c*")
            reset_attributes
            execute!
          rescue Escape
            pp @results
            @results
          end
        end

        def push(key, ts, te)
          data = @data[ts .. te.pred].pack('c*')
          case key
          when :label
            # NOTE: 1.9.* supports label key, which RubyParser cannot handle, thus
            # conversion is needed.
            @tokens << data << '' << '=>'
            @keys << :symbol << :any << :assoc
          else
            @keys << key
            @tokens << data
          end
        end

        def increment_line
          @lineno += 1
          raise Escape unless @results.empty?
        end

        def increment_counter(type, key)
          send(:"increment_#{key}_counter", type)
        end

        def decrement_counter(type, key)
          send(:"decrement_#{key}_counter")
        end

        def increment_do_end_counter(type)
          return if @brace_counter.started?
          puts '', 'inside increment_do_end_counter'
          pp @tokens
          case type
          when :do_block_nstart1 then @do_end_counter.increment
          when :do_block_nstart2 then @do_end_counter.increment(0..1)
          when :do_block_start
            offset_attributes unless @do_end_counter.started?
            @do_end_counter.increment
          end
        end

        def decrement_do_end_counter
          return unless @do_end_counter.started?
          puts '', 'inside decrement_do_end_counter'
          pp @tokens
          @do_end_counter.decrement
          construct_result_code if @do_end_counter.balanced?
        end

        def increment_brace_counter(type)
          return if @do_end_counter.started?
          puts '', 'inside increment_brace_counter'
          pp @tokens
          offset_attributes unless @brace_counter.started?
          @brace_counter.increment
        end

        def decrement_brace_counter
          return unless @brace_counter.started?
          puts '', 'inside decrement_brace_counter'
          pp @tokens
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
            @results << code
            raise Escape unless @lineno == 1
            reset_attributes
            puts '', 'inside construct_result_code'
            pp @tokens, @results
          rescue SyntaxError
          end
        end

        def reset_attributes
          @tokens = []
          @keys = []
          @lineno = 1
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
