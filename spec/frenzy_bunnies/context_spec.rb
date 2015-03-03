require 'spec_helper'
require 'frenzy_bunnies'
require 'support/workers/wrong_name_worker'

describe FrenzyBunnies::Context do
  describe 'configuration' do
    let(:ctx) {FrenzyBunnies::Context.new}
    FrenzyBunnies::Context::OPTS.each do |option|
      it "provides instance level config method #{option} <value>" do
        ctx.send(option, "TEST")
        expect(ctx.opts).to include({option => "TEST"})
        ctx.reset_to_default_config
      end
    end

    it 'EXCHANGE_DEFAULTS provides configuration of the defualt exchange' do
      expect(ctx.default_exchange).to eql (described_class::EXCHANGE_DEFAULTS)
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

      it '#reset_to_default_config resets to class level defaults' do
        ctx.reset_to_default_config
        expect(ctx.opts[:web_host]).to eql 'localhost'
      end
    end

    describe 'loading workers' do
      context 'with worker_subdomain: Subdomain' do
        let(:sub_ctx) {FrenzyBunnies::Context.new(workers_scope: 'Subdomain')}
        it 'will add any workers with a class name beginning with Subdomain that have been required' do
          expect(sub_ctx.workers).to include Subdomain::RightNameWorker
        end
      end
    end
  end
end
