require 'devise/strategies/base'
require 'devise/strategies/token_authenticatable'
module Devise
  module Strategies
    class TokenAuthenticatable
      def valid?

        valid = super
        if params[:format] == "json"
          valid = valid && ((params[:controller] == 'catalog' && params[:action] == 'document')|| (params[:controller] == 'item_lists' &&  %w{index show}.include?(params[:action])) || (params[:controller] == 'catalog' &&  %w{primary_text show annotations}.include?(params[:action])))
        else
          valid = valid && (params[:controller] == 'catalog' && params[:action] == 'document')
        end
        valid
      end
    end
  end
end