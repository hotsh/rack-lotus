module Rack
  class Nelumba
    module PJAXHelpers
      def pjax?
        env['HTTP_X_PJAX'] || request["_pjax"]
      end
    end

    helpers PJAXHelpers
  end
end
