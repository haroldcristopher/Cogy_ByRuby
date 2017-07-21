on "say_foo", desc: "Print a foo" do
  "foo"
end

on "raiser", desc: "Raises an exception" do
  raise "boom"
end

on "print_env", desc: "Test cogy env access" do
  "#{env["foo"]} #{env["COG_FOO"]} #{env["NOEXIST"]} #{env["FOO"]}"
end

on "foohelper", desc: "" do
  foo
end

on "rails_url_helpers", desc: "" do
  "#{baz_url(host: "dummy.com")} #{baz_path}"
end

on "titleize", desc: "" do
  bar "this should be titleized"
end

on "args_order", args: [:a, :b, :c], desc: "" do
  args.join
end

on "test_opts_downcased",
   opts: { a: { type: "string", required: false } },
   desc: "" do
  opts[:a]
end

on "examples_as_array", desc: "", examples: ["foo", "bar"] do
end
