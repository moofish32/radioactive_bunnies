require 'spec_helper'
require 'frenzy_bunnies'

describe FrenzyBunnies::Context do
  describe 'configuration' do
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

    describe 'instance level configurations' do
      let(:username) { username = 'just a test'}
      before do
        ctx.username(username)
        ctx.web_host('192.168.1.1')
      end

      it 'allows instance level overrides for all class level settings' do
        expect(ctx.opts[:username]).to eql username
      end

      it 'instance configurations do NOT change class level configs' do
        expect(ctx.opts[:username]).to eql username
        expect(FrenzyBunnies::Context.config[:username]).to be_falsey
      end

      it '#reset_to_default_config resets to class level defaults' do
        ctx.reset_to_default_config
        expect(ctx.opts[:web_host]).to eql 'localhost'
      end

    end
  end
end
