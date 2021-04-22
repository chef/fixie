# -*- indent-tabs-mode: nil; fill-column: 110 -*-
require "rspec"
require "spec_helper"
require "chef_fixie"
require "chef_fixie/config"

RSpec.describe ChefFixie::Sql::Groups, "Group access" do
  let (:test_org_name) { "ponyville" }
  let (:orgs) { ChefFixie::Sql::Orgs.new }
  let (:users) { ChefFixie::Sql::Users.new }
  let (:test_org) { orgs[test_org_name] }

  # TODO this should use a freshly created object and purge it afterwords.
  # But we need to write the create object feature still

  context "Groups" do
    let (:testgroup) { test_org.groups["admins"] }
    let (:adminuser) { users["rainbowdash"] }
    let (:notadminuser) { users["mary"] }

    it "Members are part of the group" do
      expect(testgroup.member?(adminuser)).to be true
    end
    it "Members are not part of the group" do
      expect(testgroup.member?(notadminuser)).to be false
    end

  end

end
