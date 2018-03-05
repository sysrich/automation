# A module containing helper methods to create a testing environment
# for end to end tests.
module Helpers
  def with_screenshot(name:, &block)
    $counter ||= 0
    formatted_counter = format('%02d', $counter)
    save_screenshot("screenshots/#{formatted_counter}_before_#{name}.png", full: true)
    yield
    save_screenshot("screenshots/#{formatted_counter}_after_#{name}.png", full: true)
    $counter += 1
  end

  def with_status_ok(&block)
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

    # Generic Settings Section
    fill_in "settings_dashboard", with: environment["dashboardHost"] || default_ip_address

    # Cluster Services Section
    if ENV.fetch("ENABLE_TILLER", false)
      check "settings[tiller]"
    else
      uncheck "settings[tiller]"
    end

    # Proxy Settings Section
    if environment.fetch("proxy", {}).fetch("enabled", false)
      find('#settings_enable_proxy_enable').trigger('click')
      # Nasty hack to let the panel open
      sleep 2
      fill_in "settings_http_proxy", with: environment["proxy"]["http_proxy"]
      fill_in "settings_https_proxy", with: environment["proxy"]["https_proxy"]
      fill_in "settings_no_proxy", with: environment["proxy"]["no_proxy"] || "localhost, 127.0.0.1"

      if environment["proxy"]["systemwide"]
        find('#settings_proxy_systemwide_true').trigger('click')
      else
        find('#settings_proxy_systemwide_false').trigger('click')
      end
    else
      find('#settings_enable_proxy_disable').trigger('click')
    end
    # Proxy Settings Section
    if environment.fetch("suse_registry_mirror", {}).fetch("enabled", false)
      find('#settings_suse_registry_mirror_enabled_enable').trigger('click')
      # Nasty hack to let the panel open
      sleep 2
      fill_in "settings_suse_registry_mirror_url", with: environment["suse_registry_mirror"]["url"]

      if environment["suse_registry_mirror"]["certificate"]
        find('#settings_suse_registry_mirror_certificate_enabled_true').trigger('click')
        # Nasty hack to let the panel open
        sleep 2
        fill_in "settings_suse_registry_mirror_certificate", with: environment["suse_registry_mirror"]["certificate"]
      else
        find('#settings_suse_registry_mirror_certificate_enabled_false').trigger('click')
      end
    else
      find('#settings_suse_registry_mirror_enabled_disable').trigger('click')
    end

    click_on "Next"
    puts "<<< Velum set up"
  end
end

RSpec.configure { |config| config.include Helpers, type: :feature }
