require 'cucumber/formatter/progress'

module Cucumber
  module Formatter
    class Progress
      def exception(exception, status)
        @exception_raised = true
        if exception.kind_of?(Cucumber::Ast::Table::Different)
          @io.puts(exception.table)
          @io.flush
        end
      end
    end
  end
end