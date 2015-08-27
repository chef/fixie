# -*- indent-tabs-mode: nil; fill-column: 110 -*-
require 'rspec'
require "spec_helper"
require 'chef_fixie'
require 'chef_fixie/config'

RSpec.describe ChefFixie::CheckOrgAssociations, "Association checker" do
  let (:test_org_name) { "ponyville"}
  let (:orgs) { ChefFixie::Sql::Orgs.new }
  let (:test_org) { orgs[test_org_name] }

  let (:users) { ChefFixie::Sql::Users.new }
  let (:adminuser) { users['rainbowdash'] }
  let (:notorguser) { users['mary'] }

  # TODO this should use a freshly created object and purge it afterwords.
  # But we need to write the create object feature still

  context "Individual user check" do
    it "Works on expected sane org/user pair" do
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be true
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org_name, adminuser.name)).to be true
    end

  end
  context "Individual user check" do
    before :each do
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be true
    end

    after :each do
      usag =  test_org.groups[adminuser.id]

      usag.group_add(adminuser)
      test_org.groups['users'].group_add(usag)

      adminuser.ace_add(:read, test_org.global_admins)

    end

    it "Detects user not associated" do
      # break it
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, notorguser)).to be :not_associated
    end

    # TODO: Write missing USAG test, but can't until we can restore the USAG or use disposable org

    it "Detects user missing from usag" do
      # break it
      usag =  test_org.groups[adminuser.id]
      usag.group_delete(adminuser)

      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be :user_not_in_usag
    end

    it "Detects usag missing from users group" do
      # break it
      usag =  test_org.groups[adminuser.id]
      test_org.groups['users'].group_delete(usag)

      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be :usag_not_in_users
    end

    it "Detects global admins missing read" do
      # break it
      adminuser.ace_delete(:read, test_org.global_admins)

      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be :global_admins_lacks_read
    end

    # TODO test zombie invite; need some way to create it.

  end

  context "Individual user fixup" do
    before :each do
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be true
    end

    after :each do
      usag =  test_org.groups[adminuser.id]

      usag.group_add(adminuser)
      test_org.groups['users'].group_add(usag)

      adminuser.ace_add(:read, test_org.global_admins)

    end

    it "Detects user not associated" do
      # break it
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, notorguser)).to be :not_associated
    end

    # TODO: Write missing USAG test, but can't until we can restore the USAG or use disposable org

    it "Fixes user missing from usag" do
      # break it
      usag =  test_org.groups[adminuser.id]
      usag.group_delete(adminuser)

      expect(ChefFixie::CheckOrgAssociations.fix_association(test_org, adminuser)).to be true
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be true
    end

    it "Fixes usag missing from users group" do
      # break it
      usag =  test_org.groups[adminuser.id]
      test_org.groups['users'].group_delete(usag)

      expect(ChefFixie::CheckOrgAssociations.fix_association(test_org, adminuser)).to be true
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be true
    end

    it "Fixes global admins missing read" do
      # break it
      adminuser.ace_delete(:read, test_org.global_admins)

      expect(ChefFixie::CheckOrgAssociations.fix_association(test_org, adminuser)).to be true
      expect(ChefFixie::CheckOrgAssociations.check_association(test_org, adminuser)).to be true
    end

    # TODO test zombie invite; need some way to create it.

  end


  # TODO Break the org and check it!
  context "Global org check" do

    it "Works on expected sane org" do
      expect(ChefFixie::CheckOrgAssociations.check_associations("acme")).to be true
      expect(ChefFixie::CheckOrgAssociations.check_associations(orgs["acme"])).to be true
    end

  end

  

end
