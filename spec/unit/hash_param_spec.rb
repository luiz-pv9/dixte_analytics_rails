require 'rails_helper'
require 'hash_param'

describe HashParam do
	describe '.has_keys' do
		it 'returns true if all the specified keys are present in the hash' do
			expect(HashParam.has_keys([:a, :b], {:a => 10, :b => 20})).to be(true)
			expect(HashParam.has_keys([:a], {:a => 10, :b => 20})).to be(true)
			expect(HashParam.has_keys([:a], {:a => 10})).to be(true)
		end

		it 'returns false if not all keys are in the hash' do
			expect(HashParam.has_keys([:a, :b], {:b => 20})).to be(false)
			expect(HashParam.has_keys([:a], {:b => 10})).to be(false)
		end
	end
end