require "test_helper"

module Cogy
  class CommandTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup { @routes = Engine.routes }

    def test_error_tmpl_message
      get "/cogy/cmd/raiser/george"
      assert response.body.include?("boom")
    end

    def test_error_tmpl_contenttype
      get "/cogy/cmd/raiser/george"
      assert_equal "text/plain", response.content_type.to_s
    end
  end
end
