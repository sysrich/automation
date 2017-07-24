# A module containing helper methods to create a testing environment
# for end to end tests.
module Helpers
  # This method can be used to wait for something to happen.
  # E.g. Wait for a record to appear in the velum-dashboard database.
  # timeout is the number of seconds before the loop is exited
  # inteval is the number of seconds to wait before next invocation of the block
  # block is the code that must return true to exit the loop
  #
  # The method return false if the timeout is reached or the block never returns
  # true.
  def wait_for(timeout:, interval: 1, task: :noname, &block)
    start_time = Time.now
    loop do
      if Time.now - start_time > timeout
        save_screenshot("screenshots/timeout.png", full: true)
        fail("Timed out")
      end
      if yield == true
        save_screenshot("screenshots/#{task}.png", full: true)
        return true
      end
      sleep interval
    end
  end

  private

  def login
    puts ">>> User logs in"
    visit "/users/sign_in"
    fill_in "user_email", with: "test@test.com"
    fill_in "user_password", with: "password"
    click_on "Log in"
    puts "<<< User logged in"
  end

  def register
    puts ">>> Registering user"
    visit "/users/sign_up"
    fill_in "user_email", with: "test@test.com"
    fill_in "user_password", with: "password"
    fill_in "user_password_confirmation", with: "password"
    click_on "Create Admin"
    puts "<<< User registered"
  end

  def default_interface
    `awk '$2 == 00000000 { print $1 }' /proc/net/route`.strip
  end

  def default_ip_address
    `ip addr show #{default_interface} | awk '$1 == "inet" {print $2}' | cut -f1 -d/`.strip
  end

  def configure
    puts ">>> Setting up velum"
    visit "/setup"
    fill_in "settings_dashboard", with: environment["dashboardHost"] || default_ip_address
    fill_in "settings_apiserver", with: environment["kubernetesHost"]
    click_on "Next"
    puts "<<< Velum set up"
  end
end

RSpec.configure { |config| config.include Helpers, type: :feature }
