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

    def test_calc_command
      get "/cogy/cmd/calc/george", cog_opt_op: "+", cog_argv_0: 1, cog_argv_1: 2
      assert_equal "Hello george, the answer is: 3", response.body

      get "/cogy/cmd/calc/george", cog_opt_op: "/", cog_argv_0: 10, cog_argv_1: 5
      assert_equal "Hello george, the answer is: 2", response.body
    end
  end
end
