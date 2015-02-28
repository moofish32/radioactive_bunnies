require 'spec_helper'
require 'frenzy_bunnies'

describe FrenzyBunnies::Context do
  describe 'configuration' do
    before { FrenzyBunnies::Context.clear_config }
    let(:ctx) { FrenzyBunnies::Context.new }

    FrenzyBunnies::Context::OPTS.each do |option|
      it "provides class level methods #{option} <value>" do
        FrenzyBunnies::Context.send(option, "TEST")
        expect(FrenzyBunnies::Context.config).to include({option => "TEST"})
      end
    end

    it 'uses the class level settings insted of default values' do
      FrenzyBunnies::Context.heartbeat(20)
      expect(ctx.opts[:heartbeat]).to eql 20
      ctx.stop
    end
    it '#default_exchange provides configuration of the defualt exchange' do
      expect(ctx.default_exchange).to match described_class.exchange_defaults
      ctx.stop
    end
  end
end
