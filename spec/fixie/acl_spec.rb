
require 'rspec'
require "spec_helper"
require 'fixie'
require 'fixie/config'

RSpec.describe Fixie::Sql::Orgs, "ACL access" do
  let (:test_org_name) { "ponyville"}
  let (:orgs) { Fixie::Sql::Orgs.new }
  let (:users) { Fixie::Sql::Users.new }
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




end
