
require "rspec"
require "spec_helper"
require "chef_fixie"
require "chef_fixie/config"

RSpec.describe ChefFixie::Sql::Orgs, "Organizations access" do
  let (:test_org_name) { "ponyville" }
  let (:orgs) { ChefFixie::Sql::Orgs.new }
  let (:test_org) { orgs[test_org_name] }

  context "Basic functionality of org accessor" do

    it "Org has a name and id" do
      expect(test_org.name).to eq(test_org_name)
      expect(test_org.id).not_to be_nil
    end

    it "Org has a global admins group" do
      expect(test_org.global_admins.name).to eq(test_org_name + "_global_admins")
    end

  end

end
