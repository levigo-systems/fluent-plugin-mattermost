require "helper"
require "fluent/plugin/out_mattermost.rb"

class MattermostOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::MattermostOutput).configure(conf)
  end
end
