
require 'rspec'
require "spec_helper"
require 'chef_fixie'
require 'chef_fixie/config'

RSpec.describe ChefFixie::Sql::Orgs, "ACL access" do
  let (:test_org_name) { "ponyville"}
  let (:orgs) { ChefFixie::Sql::Orgs.new }
  let (:users) { ChefFixie::Sql::Users.new }
  let (:test_org) { orgs[test_org_name] }

  # TODO this should use a freshly created object and purge it afterwords.
  # But we need to write the create object feature still
  
  context "Fetch acl for actor (client)" do
    let (:testclient) { test_org.clients.all.first }
    let (:testuser) { users['spitfire'] }
    let (:pivotal) { users['pivotal'] }
    let (:client_container) { test_org.containers["clients"] }
    
    it "We can fetch the acl" do
      acl = testclient.acl
      expect(acl.keys).to include(* %w(create read update delete grant))
    end

    it "we can add a user to an ace" do
# This requires either a temp object or good cleanup      
#      acl = testclient.acl
#      expect(acl["read"]["actors"].not_to include("wonderbolts")
      
      testclient.ace_add(:read, testuser)

      acl = testclient.acl
      expect(acl["read"]["actors"]).to include([:global, testuser.name])
    end
    
    it "we can add then delete a user from an ace" do
      testclient.ace_add(:read, testuser)
      acl = testclient.acl
      expect(acl["read"]["actors"]).to include([:global, testuser.name])

      
      testclient.ace_delete(:read, testuser)

      acl = testclient.acl
      expect(acl["read"]["actors"]).not_to include([:global, testuser.name])
    end

    it "we can copy users from another acl" do
      testclient.ace_delete(:all, pivotal)
            
      testclient.acl_add_from_object(client_container)

      acl = testclient.acl
      %w(create read update delete grant).each do |action|
        expect(acl[action]["actors"]).to include([:global, pivotal.name])
      end
    end
     
  end

  context "ACE Membership" do
    
    let (:admingroup) { test_org.groups['admins'] }
    let (:testobject) { test_org.groups['admins'] }
    let (:notadmingroup) { test_org.groups['clients'] }
    let (:adminuser) { users['rainbowdash'] }
    let (:notadminuser) { users['mary'] }
    let (:pivotal) { users['pivotal'] }
    
    it "Privileged users and groups are part of the read ACE" do
      expect(testobject.ace_member?(:read, admingroup)).to be true
      expect(testobject.ace_member?(:read, pivotal)).to be true
    end
    it "Unprivileged members are not part of read ACE" do
      expect(testobject.member?(notadmingroup)).to be false
      expect(testobject.member?(notadminuser)).to be false
    end
  end


end
