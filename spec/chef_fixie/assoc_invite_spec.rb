
require 'rspec'
require "spec_helper"
require 'chef_fixie'
require 'chef_fixie/config'

RSpec.describe ChefFixie::Sql::Associations, "Associations tests" do
  let (:test_org_name) { "ponyville" }
  let (:orgs) { ChefFixie::Sql::Orgs.new }
  let (:test_org) { orgs[test_org_name]}

  let (:users) { ChefFixie::Sql::Users.new }
  let (:assocs) { ChefFixie::Sql::Associations.new }


  context "Basic functionality of association spec" do
    let ("test_user_name") { "fluttershy" }
    let ("test_user") { users[test_user_name] }
    it "Can fetch by user id" do
      assocs_by_user = assocs.by_user_id(test_user.id).all
      expect(assocs_by_user).not_to be_nil
      expect(assocs_by_user.count).to eq(1)
      expect(assocs_by_user.first.user_id ).to eq(test_user.id)
      expect(assocs_by_user.first.org_id ).to eq(test_org.id)
    end
    it "Can fetch by org id" do
      assocs_by_org = assocs.by_org_id(test_org.id).all
      expect(assocs_by_org).not_to be_nil
      expect(assocs_by_org.count).to be > 1
      expect(assocs_by_org.first.org_id).to eq(test_org.id)
    end

    it "Can fetch by both org/user id" do
      assoc_item = assocs.by_org_id_user_id(test_org.id, test_user.id)
      expect(assoc_item).not_to be_nil
      expect(assoc_item.user_id).to eq(test_user.id)
      expect(assoc_item.org_id).to eq(test_org.id)

      # test user not in org
      expect(assocs.by_org_id_user_id(test_org.id, users['mary'].id)).to be_nil
    end


  end


end
