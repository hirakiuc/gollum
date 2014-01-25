module Precious
  module Views
    class Top < Layout
      def auth_path
        "#{@base_url}/auth/gapps"
      end
    end
  end
end
