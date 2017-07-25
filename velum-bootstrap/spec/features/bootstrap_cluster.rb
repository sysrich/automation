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

  scenario "User registers" do
    register
  end

  scenario "User configures the cluster" do
    configure
  end

  scenario "User accepts all minions" do
    visit "/setup/discovery"

    puts ">>> Wait until all minions are pending to be accepted"
    expect(page).to have_selector("a", text: "Accept Node", count: node_number, wait: 120)
    puts "<<< All minions are pending to be accepted"

    puts ">>> Wait for accept-all button to be enabled"
    expect(page).to have_button("accept-all", disabled: false, wait: 20)
    puts "<<< accept-all button enabled"

    puts ">>> Click to accept all minion keys"
    click_button("accept-all")

    puts ">>> Wait until Minion keys are accepted by salt"
    expect(page).to have_css("input[type='radio']", count: node_number, wait: 120)
    puts "<<< Minion keys accepted in Velum"

    puts ">>> Waiting until Minions are accepted in Velum"
    expect(page).to have_text("#{node_number} nodes found", wait: 30)
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
    save_screenshot("screenshots/minions_selected.png", full: true)

    puts ">>> Selecting master minion"
    within("tr", text: master_minion["minionID"]) do
      find("input[type='radio']").click
    end
    puts "<<< Master minion selected"
    save_screenshot("screenshots/master_selected.png", full: true)

    puts ">>> Bootstrapping cluster"
    click_on 'Bootstrap cluster'

    if node_number < 3
      # a modal with a warning will appear as we only have #{node_number} nodes
      expect(page).to have_content("Cluster is too small")
      click_button "Proceed anyway"
    end
    puts "<<< Cluster bootstrapped"
    save_screenshot("screenshots/cluster_bootstrapped.png", full: true)

    puts ">>> Wait until UI is loaded"
    within(".nodes-container") do
      expect(page).to have_no_css(".nodes-loading", wait: 30)
    end
    puts "<<< UI loaded"

    puts ">>> Wait until orchestration is complete"
    within(".nodes-container") do
      expect(page).to have_css(".fa-spin", count: 0, wait: 600)
    end
    puts "<<< Orchestration completed"

    puts ">>> Checking orchestration success"
    within(".nodes-container") do
      expect(page).to have_css(".fa-check-circle-o", count: node_number)
    end
  end
end
