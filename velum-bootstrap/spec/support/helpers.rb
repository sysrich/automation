# A module containing helper methods to create a testing environment
# for end to end tests.
module Helpers
  def with_screenshot(name:)
    save_screenshot("screenshots/#{Time.now.to_i}_before_#{name}.png", full: true)
    yield
    save_screenshot("screenshots/#{Time.now.to_i}_after_#{name}.png", full: true)
  end

  def with_status_ok
    yield
    expect(page.status_code).to eq(200)
  end

  private

  def login
    puts ">>> User logs in"
    with_status_ok do
      visit "/users/sign_in"
    end

    fill_in "user_email", with: "test@test.com"
    fill_in "user_password", with: "password"
    click_on "Log in"
    puts "<<< User logged in"
  end

  def register
    puts ">>> Registering user"
    with_status_ok do
      visit "/users/sign_up"
    end

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
    with_status_ok do
      visit "/setup"
    end

    fill_in "settings_dashboard", with: environment["dashboardHost"] || default_ip_address

    # check Tiller checkbox
    if ENV.fetch("ENABLE_TILLER", false) == "true"
      puts ">>> Enabling Tiller"
      check "settings[tiller]"
    else
      puts ">>> Disabling Tiller"
      uncheck "settings[tiller]"
    end

    # choose cri-o engine by pressing button
    if ENV.fetch("CHOOSE_CRIO", false) == "true"
      # using the "chose" function fails with a MouseEventFailed overlap error
      page.find('#settings_container_runtime_crio').trigger(:click)
    else
      page.find('#settings_container_runtime_docker').trigger(:click)
    end
    click_on "Next"
    puts "<<< Velum set up"
  end
end

RSpec.configure { |config| config.include Helpers, type: :feature }
