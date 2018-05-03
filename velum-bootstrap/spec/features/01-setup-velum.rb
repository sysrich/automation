require 'spec_helper'
require 'yaml'

feature 'Register user and configure cluster' do
  before do
    login unless inspect.include? 'User registers'
  end

  # Using append after in place of after, as recommended by
  # https://github.com/mattheworiordan/capybara-screenshot#common-problems
  append_after do
    Capybara.reset_sessions!
  end

  scenario 'User registers' do
    with_screenshot(name: :register) do
      register
    end
  end

  scenario 'User configures the cluster' do
    with_screenshot(name: :configure) do
      configure
    end
  end
end
