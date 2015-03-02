require 'spec_helper'
require 'frenzy_bunnies'

describe FrenzyBunnies::Context do
  describe 'configuration' do
    before do
      FrenzyBunnies::Context.reset_default_config
      fake_connection = Object.new
      allow(fake_connection).to receive(:on_shutdown).and_return(true)
      allow(MarchHare).to receive(:connect).and_return(fake_connection)
    end
    let(:ctx) {FrenzyBunnies::Context.new }
    FrenzyBunnies::Context::OPTS.each do |option|
      it "provides class level methods #{option} <value>" do
        FrenzyBunnies::Context.send(option, "TEST")
        expect(FrenzyBunnies::Context.config).to include({option => "TEST"})
        FrenzyBunnies::Context.reset_default_config
      end
    end

    it 'uses the class level settings insted of default values' do
      FrenzyBunnies::Context.heartbeat(20)
      expect(ctx.opts[:heartbeat]).to eql 20
    end
    it '#default_exchange provides configuration of the defualt exchange' do
      expect(ctx.default_exchange).to eql (described_class.exchange_defaults)
    end
  end
end
