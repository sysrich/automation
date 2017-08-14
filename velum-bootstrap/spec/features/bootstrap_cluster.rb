require "spec_helper"
require 'yaml'

feature "Boostrap cluster" do

  let(:node_number) { environment["minions"].count { |element| element["role"] != "admin" } }
  let(:hostnames) { environment["minions"].map { |m| m["fqdn"].downcase if m["role"] != "admin" }.compact }
  let(:master_minion) { environment["minions"].detect { |m| m["role"] == "master" } }

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

  scenario "User registers" do
    with_screenshot(name: :register) do
      register
    end
  end

  scenario "User configures the cluster" do
    with_screenshot(name: :configure) do
      configure
    end
  end

  scenario "User accepts all minions" do
    visit "/setup/discovery"

    puts ">>> Wait until all minions are pending to be accepted"
    with_screenshot(name: :pending_minions) do
      expect(page).to have_selector("a", text: "Accept Node", count: node_number, wait: 120)
    end
    puts "<<< All minions are pending to be accepted"

    puts ">>> Wait for accept-all button to be enabled"
    with_screenshot(name: :accept_button_enabled) do
      expect(page).to have_button("accept-all", disabled: false, wait: 20)
    end
    puts "<<< accept-all button enabled"

    puts ">>> Click to accept all minion keys"
    with_screenshot(name: :accept_button_click) do
      click_button("accept-all")
    end

    # ugly workaround for https://bugzilla.suse.com/show_bug.cgi?id=1050450
    # FIXME: drop it when bug is fixed
    sleep 30
    visit "/setup/discovery"

    puts ">>> Wait until Minion keys are accepted by salt"
    with_screenshot(name: :accepted_keys) do
      expect(page).to have_css("input[type='radio']", count: node_number, wait: 600)
    end
    puts "<<< Minion keys accepted in Velum"

    puts ">>> Waiting until Minions are accepted in Velum"
    with_screenshot(name: :accepted_minions) do
      expect(page).to have_text("#{node_number} nodes found", wait: 60)
    end
    puts "<<< Minions accepted in Velum"

    # They should also appear in the UI
    hostnames.each do |hostname|
      expect(page).to have_content(hostname)
    end
  end

  scenario "User selects a master and bootstraps the cluster" do
    visit "/setup/discovery"

    puts ">>> Selecting all minions"
    with_screenshot(name: :select_all_minions) do
      find(".check-all").click
    end
    puts "<<< All minions selected"

    puts ">>> Selecting master minion"
    with_screenshot(name: :select_master) do
      within("tr", text: master_minion["minionId"] || master_minion["minionID"]) do
        find("input[type='radio']").click
      end
    end
    puts "<<< Master minion selected"

    puts ">>> Bootstrapping cluster"
    with_screenshot(name: :bootstrap_cluster) do
      click_on "Bootstrap cluster"
    end

    if node_number < 3
      # a modal with a warning will appear as we only have #{node_number} nodes
      with_screenshot(name: :cluster_too_small) do
        expect(page).to have_content("Cluster is too small")
        click_button "Proceed anyway"
      end
    end
    puts "<<< Cluster bootstrapped"

    puts ">>> Wait until UI is loaded"
    with_screenshot(name: :ui_loaded) do
      within(".nodes-container") do
        expect(page).to have_no_css(".nodes-loading", wait: 30)
      end
    end
    puts "<<< UI loaded"

    puts ">>> Wait until orchestration is complete"
    with_screenshot(name: :orchestration_complete) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-spin", count: 0, wait: 900)
      end
    end
    puts "<<< Orchestration completed"

    puts ">>> Checking orchestration success"
    with_screenshot(name: :orchestration_success) do
      within(".nodes-container") do
        expect(page).to have_css(".fa-check-circle-o", count: node_number, wait: 120)
      end
    end

    puts ">>> Download kubeconfig"
    with_screenshot(name: :download_kubeconfig) do
      data = page.evaluate_script("\
        function() {
          var url = window.location.protocol + '//' + window.location.host + '/kubectl-config';\
          var xhr = new XMLHttpRequest();\
          xhr.open('GET', url, false);\
          xhr.send(null);\
          return xhr.responseText;\
        }()
      ")
      File.write("kubeconfig", data)
    end
  end
end
