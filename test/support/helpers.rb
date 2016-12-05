require "active_support/test_case"

class ActiveSupport::TestCase
  def cmd(name, env={}, as="someone")
    post "/cogy/cmd/#{name}/#{as}", env
  end

  def fetch_inventory
    get "/cogy/inventory"
    YAML.load(response.body)
  end

  def with_config(opts={})
    old = {}

    opts.each do |k, v|
      old[k] = Cogy.send(k)
      Cogy.send("#{k}=", v)
    end

    yield fetch_inventory

    old.each do |k, v|
      Cogy.send("#{k}=", v)
    end
  end

  def without_commands
    old = Cogy.commands
    Cogy.commands = {}
    yield
    Cogy.commands = old
  end
end
