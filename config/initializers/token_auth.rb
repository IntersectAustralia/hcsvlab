require 'devise/strategies/base'
require 'devise/strategies/token_authenticatable'
module Devise
  module Strategies
    class TokenAuthenticatable
      def valid?
        super && params[:format] == "json" &&((params[:controller] == 'item_lists' and (params[:action] == 'index' or params[:action] == 'show')) or (params[:controller] == 'catalog' and params[:action] == 'show'))
      end
    end
  end
end