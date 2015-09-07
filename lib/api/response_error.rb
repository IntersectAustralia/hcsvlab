# Exception class for raising HTTP response errors
class ResponseError < StandardError
  attr_reader :response_code
  def initialize(response_code=400)
    @response_code = response_code
  end
end