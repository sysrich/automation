require "spec_helper"
require 'yaml'

feature "Boostrap cluster" do

  let(:node_number) { environment["minions"].count { |element| element["role"] != "admin" } }
  let(:hostnames) { environment["minions"].map { |m| m["fqdn"] if m["role"] != "admin" }.compact }
  let(:master_minion) { environment["minions"].detect { |m| m["role"] == "master" } }

  before(:each) do
    unless self.inspect.include? "User registers"
      login
    end
  end

  after(:each) do
    # this can be dropped after velum/puma can handle multiple concurrent connections
#    Capybara.reset_session!
  end

  scenario "User registers" do
    register
  end

  scenario "User configures the cluster" do
    configure
  end

  scenario "User accepts all minions" do
    visit "/setup/discovery"

    puts ">>> Wait until all minions are pending to be accepted"
    wait_for(timeout: 600, interval: 20) do
      within("div.pending-nodes-container") do
        has_selector?("a", text: "Accept Node", count: node_number) rescue false
      end rescue false
    end
    puts "<<< All minions are pending to be accepted"

    puts ">>> Wait for accept-all button to be enabled"
    wait_for(timeout: 600, interval: 10) do
      !find_button("accept-all").disabled? rescue false
    end
    puts "<<< accept-all button enabled"

    puts ">>> Click to accept all minion keys"
    click_button("accept-all")

    puts ">>> Wait until Minion keys are accepted in Velum"
    wait_for(timeout: 600, interval: 10) do
      within("div.discovery-nodes-panel") do
        has_css?("input[type='radio']", count: node_number) rescue false
      end rescue false
    end
    puts "<<< Minion keys accepted in Velum"

    puts ">>> Waiting until Minions are accepted in Velum"
    minions_accepted = wait_for(timeout: 600, interval: 10) do
      first("h3").text == "#{node_number} nodes found"
    end
    expect(minions_accepted).to be(true)
    puts "<<< Minions accepted in Velum"

    # They should also appear in the UI
    hostnames.each do |hostname|
      expect(page).to have_content(hostname)
    end
  end

  scenario "User selects a master and bootstraps the cluster" do
    visit "/setup/discovery"

    puts ">>> Selecting all minions"
    find(".check-all").click
    puts "<<< All minions selected"

    puts ">>> Selecting master minion"
    within("tr", text: master_minion["minionID"]) do
      find("input[type='radio']").click
    end
    puts "<<< Master minion selected"

    puts ">>> Bootstrapping cluster"
    click_on 'Bootstrap cluster'

    if node_number < 3
      # a modal with a warning will appear as we only have #{node_number} nodes
      expect(page).to have_content("Cluster is too small")
      click_button "Proceed anyway"
    end
    puts "<<< Cluster bootstrapped"

    puts ">>> Wait until UI is loaded"
    ui_loaded =  wait_for(timeout: 30, interval: 10) do
      within(".nodes-container") do
        !has_css?(".nodes-loading")
      end
    end
    puts "<<< UI loaded"

    puts ">>> Wait until orchestration is complete"
    orchestration_completed = wait_for(timeout: 1500, interval: 10) do
      within(".nodes-container") do
        has_css?(".fa-spin", count: 0)
      end
    end
    expect(orchestration_completed).to be(true)
    puts "<<< Orchestration completed"

    puts ">>> Checking orchestration success"
    orchestration_successful = wait_for(timeout: 30, interval: 10) do
      within(".nodes-container") do
        has_css?(".fa-check-circle-o", count: node_number)
      end
    end
    expect(orchestration_successful).to be(true)
  end
end
