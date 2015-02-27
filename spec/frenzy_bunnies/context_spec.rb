require 'spec_helper'
require 'frenzy_bunnies'

describe FrenzyBunnies::Context do
  describe 'configuration using class level DSL' do
    before { FrenzyBunnies::Context.clear_config }
    FrenzyBunnies::Context::OPTS.each do |option|
      it "provides class level methods #{option} <value>" do
        FrenzyBunnies::Context.send(option, "TEST")
        expect(FrenzyBunnies::Context.config).to include({option => "TEST"})
      end
    end
    it 'uses the class level settings insted of default values' do
      FrenzyBunnies::Context.heartbeat(20)
      ctx = FrenzyBunnies::Context.new
      expect(ctx.opts[:heartbeat]).to eql 20
    end
  end
end
