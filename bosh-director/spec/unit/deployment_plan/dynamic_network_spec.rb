require 'spec_helper'

describe Bosh::Director::DeploymentPlan::DynamicNetwork do
  before(:each) do
    @deployment_plan = instance_double('Bosh::Director::DeploymentPlan::Planner')
  end

  let(:logger) { Logging::Logger.new('TestLogger') }

  describe :initialize do
    it "should parse spec" do
      network = BD::DeploymentPlan::DynamicNetwork.new({
          "name" => "foo",
          "cloud_properties" => {
              "foz" => "baz"
          }
      }, logger)
      expect(network.cloud_properties).to eq({"foz" => "baz"})
    end

    it "defaults cloud properties to empty hash" do
      network = BD::DeploymentPlan::DynamicNetwork.new({
          "name" => "foo",
        }, logger)
      expect(network.cloud_properties).to eq({})
    end

    it "should parse dns servers" do
      network = BD::DeploymentPlan::DynamicNetwork.new({
          "name" => "foo",
          "dns" => %w[1.2.3.4 5.6.7.8],
          "cloud_properties" => {
              "foz" => "baz"
          }
      }, logger)
      expect(network.dns).to eq(%w[1.2.3.4 5.6.7.8])
    end
  end

  describe :reserve do
    before(:each) do
      @network = BD::DeploymentPlan::DynamicNetwork.new({
          "name" => "foo",
          "cloud_properties" => {
              "foz" => "baz"
          }
      }, logger)
    end

    it "should reserve an existing IP" do
      reservation = BD::NetworkReservation.new(
          :ip => "0.0.0.1", :type => BD::NetworkReservation::DYNAMIC)
      @network.reserve(reservation)
      expect(reservation.reserved?).to eq(true)
      expect(reservation.ip).to eq(4294967295)
    end

    it "should not let you reserve a static IP" do
      reservation = BD::NetworkReservation.new(
          :ip => "0.0.0.1", :type => BD::NetworkReservation::STATIC)
      @network.reserve(reservation)
      expect(reservation.reserved?).to eq(false)
      expect(reservation.error).to eq(BD::NetworkReservation::WRONG_TYPE)
    end
  end

  describe :release do
    before(:each) do
      @network = BD::DeploymentPlan::DynamicNetwork.new({
          "name" => "foo",
          "cloud_properties" => {
              "foz" => "baz"
          }
      }, logger)
    end

    it "should release the IP from the subnet" do
      reservation = BD::NetworkReservation.new(
          :ip => 4294967295, :type => BD::NetworkReservation::DYNAMIC)

      @network.release(reservation)
    end

    it "should fail when the IP doesn't match the magic dynamic IP" do
      reservation = BD::NetworkReservation.new(
          :ip => 1, :type => BD::NetworkReservation::DYNAMIC)

      expect {
        @network.release(reservation)
      }.to raise_error(/magic DYNAMIC IP/)
    end
  end

  describe :network_settings do
    before(:each) do
      @network = BD::DeploymentPlan::DynamicNetwork.new({
          "name" => "foo",
          "cloud_properties" => {
              "foz" => "baz"
          }
      }, logger)
    end

    it "should provide dynamic network settings" do
      reservation = BD::NetworkReservation.new(
          :ip => 4294967295, :type => BD::NetworkReservation::DYNAMIC)
      expect(@network.network_settings(reservation, [])).to eq({
          "type" => "dynamic",
          "cloud_properties" => {"foz" => "baz"},
          "default" => []
      })
    end

    it "should set the defaults" do
      reservation = BD::NetworkReservation.new(
          :ip => 4294967295, :type => BD::NetworkReservation::DYNAMIC)
      expect(@network.network_settings(reservation)).to eq({
          "type" => "dynamic",
          "cloud_properties" => {"foz" => "baz"},
          "default" => ["dns", "gateway"]
      })
    end

    it "should fail when the IP doesn't match the magic dynamic IP" do
      reservation = BD::NetworkReservation.new(
          :ip => 1, :type => BD::NetworkReservation::DYNAMIC)
      expect {
        @network.network_settings(reservation)
      }.to raise_error(/magic DYNAMIC IP/)
    end
  end
end
