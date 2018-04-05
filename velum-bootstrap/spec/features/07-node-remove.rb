require "spec_helper"
require "yaml"

feature "Remove a Node" do

  let(:node_number) { environment["minions"].count { |element| element["role"] != "admin" } }
  let(:worker_number) { environment["minions"].count { |element| element["role"] == "worker" } }

  before(:each) do
    login
  end

  # Using append after in place of after, as recommended by
  # https://github.com/mattheworiordan/capybara-screenshot#common-problems
  append_after(:each) do
    Capybara.reset_sessions!
  end

  scenario "User removes a node" do
    with_status_ok do
      visit "/"
    end

    puts ">>> Checking if node can be removed"
    with_screenshot(name: :node_removable) do
      within(".nodes-container") do
        expect(page).to have_link(text: "Remove", count: worker_number, wait: 120)
      end
    end
    puts "<<< A node can be removed"

    puts ">>> Click to remove a node"
    with_screenshot(name: :node_removal) do
      first(".remove-node-link").click
    end

    orchestration_timeout = [[3600, 120].max, 7200].min
    puts ">>> Waiting for node removal"
    with_screenshot(name: :wait_node_removal) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o, .fa-times-circle", count: 1, wait: orchestration_timeout)
      end
    end
    puts "<<< node removal finished"

    puts ">>> Checking if node removal orchestration succeeded"
    with_screenshot(name: :node_removal_orchestration_succeeded) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o", count: node_number-1, wait: 5)
      end
    end
    puts "<<< Node removal orchestration succeeded"
  end
end
