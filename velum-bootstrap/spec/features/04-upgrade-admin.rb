require "spec_helper"
require 'yaml'

feature "Upgrade Admin Node" do

  let(:node_number) { environment["minions"].count { |element| element["role"] != "admin" } }
  let(:hostnames) { environment["minions"].map { |m| m["fqdn"] if m["role"] != "admin" }.compact }

  before(:each) do
    login
  end

  # Using append after in place of after, as recommended by
  # https://github.com/mattheworiordan/capybara-screenshot#common-problems
  append_after(:each) do
    Capybara.reset_sessions!
  end

  scenario "User clicks update admin node" do
    visit "/"

    puts ">>> Wait for update-admin-node button to be enabled"
    with_screenshot(name: :update_admin_node_button_enabled) do
      expect(page).to have_selector("a.update-admin-btn", wait: 400)
    end
    puts "<<< update-admin-node button enabled"

    puts ">>> Click to update admin node"
    with_screenshot(name: :update_admin_node_button_click) do
      find('a.update-admin-btn').click
    end
    puts ">>> update admin node clicked"

    puts ">>> Wait for reboot-admin-node button to be enabled"
    with_screenshot(name: :reboot_admin_node_button_enabled) do
      expect(page).to have_selector("button.reboot-update-btn", wait: 15)
    end
    puts "<<< reboot-admin-node button enabled"

    puts ">>> Click to reboot admin node"
    with_screenshot(name: :reboot_admin_node_button_click) do
      find('button.reboot-update-btn').click
    end
    puts ">>> reboot admin node clicked"

    # Allow 30 seconds for Velum to be shutdown before proceeding
    sleep 30

    puts ">>> Wait for Velum to recover"
    1.upto(600) do |n|
      begin
        visit "/"
        expect(page.status_code).to be(200)
        break
      rescue Exception => e
        if n == 600
          raise e
        else
          puts "... still waiting for velum to recover"
          sleep 1
        end
      end
    end
    puts "<<< Velum has recovered"
  end
end
