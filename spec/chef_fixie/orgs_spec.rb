
require 'rspec'
require "spec_helper"
require 'fixie'
require 'fixie/config'

RSpec.describe Fixie::Sql::Orgs, "Organizations access" do
  let (:test_org) { "ponyville"}

  context "Basic access to orgs" do
    let (:orgs) { Fixie::Sql::Orgs.new }
    it "We find more than one org" do
      expect(orgs.inner.count).to be > 0
    end

    it "We can list orgs" do
      # array matcher requires a splat. (I didn't know this )
      expect(orgs.list).to include( * %w(acme ponyville wonderbolts) )
    end
    it "We can list orgs with a limit" do
      # array matcher requires a splat. (I didn't know this )
      expect(orgs.list(1)).to eq(:too_many_results)
    end

    it "We can find an org" do
      expect(orgs[test_org].name).to eq(test_org)
    end

  end

  context "Search accessors work correctly" do
    let (:orgs) { Fixie::Sql::Orgs.new }
    let (:the_org) { orgs[test_org] }

    it "We can find an org by name" do
      expect(orgs.by_name(test_org).all.count).to eq(1)
      expect(orgs.by_name(test_org).all.first.name).to eq(the_org.name)
    end

    # TODO: Automatically extract this from the filter by field
    %w(name, id, full_name, authz_id).each do |accessor|
      it "We can access an org by #{accessor}" do
        expect(orgs.by_name(test_org).all.count).to eq(1)
        expect(orgs.by_name(test_org).all.first.name).to eq(the_org.name)
      end
    end

  end




end
