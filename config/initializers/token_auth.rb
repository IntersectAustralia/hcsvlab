require 'devise/strategies/base'
require 'devise/strategies/token_authenticatable'
module Devise
  module Strategies
    class TokenAuthenticatable
      def valid?
        valid = super
        if params[:format] == "json" 
          valid = valid and ((params[:controller] == 'item_lists' and (params[:action] == 'index' or params[:action] == 'show')) or (params[:controller] == 'catalog' and params[:action] == 'show'))
        else
          valid = valid and (params[:controller] == 'catalog' and (params[:action] == 'primary_text' or params[:action] == 'document'))
        end
        valid
      end
    end
  end
end