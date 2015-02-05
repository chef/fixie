
require 'rspec'
require "spec_helper"
require 'fixie'
require 'fixie/config'

RSpec.describe Fixie::Sql::Orgs, "Organizations access" do
  context "Basic access to orgs" do
    it "We find more than one org" do
      orgs = Fixie::Sql::Orgs.new

      
      expect(orgs.inner.count).to be > 0
    end
  end
end
