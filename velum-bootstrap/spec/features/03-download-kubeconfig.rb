require "spec_helper"
require 'yaml'

feature "Download Kubeconfig" do
  before(:each) do
    unless self.inspect.include? "User registers"
      login
    end
  end

  # Using append after in place of after, as recommended by
  # https://github.com/mattheworiordan/capybara-screenshot#common-problems
  append_after(:each) do
    Capybara.reset_sessions!
  end

  scenario "User downloads the kubeconfig file" do
    visit "/"

    expect(page).to have_text("You currently have no nodes to be accepted for bootstrapping", wait: 240)

    expect(page).to have_text("kubectl config")
    with_screenshot(name: :download_kubeconfig) do
      click_on "kubectl config"
    end
    expect(page).to have_text("Log in to Your Account")
    with_screenshot(name: :oidc_login) do
      fill_in "login", with: "test@test.com"
      fill_in "password", with: "password"
      click_button "Login"
    end
    expect(page).to have_text("apiVersion")
    File.write("kubeconfig", Nokogiri::HTML(page.body).xpath("//pre").text)
  end
end
