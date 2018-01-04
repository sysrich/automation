require "spec_helper"
require 'yaml'

feature "update Admin Node" do

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

  scenario "User clicks update all nodes" do
    visit "/"

    puts ">>> Wait for update-all-nodes button to be enabled"
    with_screenshot(name: :update_all_nodes_button_enabled) do
      expect(page).to have_link(id: "update-all-nodes", wait: 120)
    end
    puts "<<< update-all-nodes button enabled"

    puts ">>> Wait until all minions are pending an update"
    with_screenshot(name: :pending_update) do
      expect(page).to have_text("Update Available", count: node_number, wait: 120)
    end
    puts "<<< All minions are pending an update"

    puts ">>> Click to update all nodes"
    with_screenshot(name: :update_all_nodes_button_click) do
      find('#update-all-nodes').click
    end
    puts ">>> update all nodes clicked"

    # Allow 10 seconds for Velum to re-render nodes with spinners
    sleep 10

    puts ">>> Wait until update is complete"
    with_screenshot(name: :update_complete) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o", count: node_number, wait: 1800)
      end
    end
    puts "<<< Update completed"
  end
end
