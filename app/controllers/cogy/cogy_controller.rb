require_dependency "cogy/application_controller"

module Cogy
  class CogyController < ApplicationController
    # GET <mount_path>/cmd/:cmd/:user
    def command
      cmd = params[:cmd]
      args = request.query_parameters.select { |k,_| k !~ /\Acog_opt_/ }.values
      opts = request.query_parameters.select { |k,_| k =~ /\Acog_opt_/ }
        .transform_keys { |k| k.sub("cog_opt_", "") }
      user = params[:user]

      begin
        render text: Cogy.commands[cmd].run!(args, opts, user)
      rescue => e
        @user = user
        @cmd = cmd
        @exception = e
        respond_to do |format|
          format.any do
            render "/cogy/error.text.erb", content_type: "text/plain", status: 500
          end
        end
      end
    end

    # GET /inventory
    def inventory
      render text: Cogy.bundle_config.to_yaml, content_type: "application/x-yaml"
    end
  end
end
