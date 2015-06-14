require 'spec_helper'
require 'radioactive_bunnies/ext/util'
describe RadioactiveBunnies::Ext::Util do

  before do
    module TestModule
      class TestClass
      end
    end
  end

  describe '.constantize!(const_name)' do
    it 'returns the constant name for the string' do
      expect(described_class.constantize!(TestModule::TestClass.name)).
        to be TestModule::TestClass
    end
    it 'raises an error when the const is not loaded' do
      expect{ described_class.constantize!('SomeClass::Boom') }.
        to raise_error NameError
    end
  end

  describe '.constantize(const_name)' do
    it 'returns nil for undefined constants' do
      expect(described_class.constantize('SomeClass::Boom')).
        to be nil
    end
  end
end
