require 'spec_helper'
require 'frenzy_bunnies'

describe FrenzyBunnies::Context do
  describe 'configuration' do
    let(:ctx) {FrenzyBunnies::Context.new(workers_path: 'spec/support/workers')}
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

      it 'instance configurations do NOT change class level configs' do
        expect(ctx.opts[:username]).to eql username
        expect(FrenzyBunnies::Context.config[:username]).to be_falsey
      end

      it '#reset_to_default_config resets to class level defaults' do
        ctx.reset_to_default_config
        expect(ctx.opts[:web_host]).to eql 'localhost'
      end
    end

    describe 'loading workers' do
      context 'with worker_path' do
        it 'loads all workers found in the worker_path option' do
          expect(ctx.workers.size).to eql 4
        end

        it 'will not add RightNameWorker because the file is named wrong_name_worker.rb' do
          expect(ctx.workers).to_not include Subdomain::RightNameWorker
        end
      end

      context 'with worker_subdomain: Subdomain' do
        let(:sub_ctx) {FrenzyBunnies::Context.new(workers_subdomain: 'Subdomain')}
        it 'will add any workers with a class name beginning with Subdomain' do
          expect(sub_ctx.workers).to include Subdomain::RightNameWorker
        end
      end

      context 'with worker_subdomain and worker_path' do
        let(:combo_ctx) {FrenzyBunnies::Context.new(workers_path: 'spec/support/workers',
                                                    workers_subdomain: 'Subdomain') }
        it 'adds any workers in the subdomain that are loaded, regardless of path' do
          module Subdomain
            class AddingWorker; include FrenzyBunnies::Worker; end
          end
          expect(combo_ctx.workers).to include(Subdomain::RightNameWorker, Subdomain::AddingWorker)
          expect(combo_ctx.workers.size).to eql 2
        end
      end
    end
  end
end
