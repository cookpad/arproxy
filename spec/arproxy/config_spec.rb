require "spec_helper"

describe Arproxy::Config do
  describe "#adapter default value" do
    subject { Arproxy::Config.new.adapter }

    context "when Rails is defined" do
      let(:rails) { Module.new }

      around do |example|
        Object.const_set("Rails", rails)
        example.run
        Object.send(:remove_const, "Rails")
      end

      before do
        allow(rails).to receive_message_chain("application.config_for") { database_config }
      end

      context "when adapter is configured in database.yml" do
        let(:database_config) { { "adapter" => "mysql2" } }

        it { should == "mysql2" }
      end

      context "when adapter isn't configured in database.yml" do
        let(:database_config) { {} }

        it { should == nil }
      end
    end

    context "when Rails isn't defined" do
      it { should == nil }
    end
  end
end
