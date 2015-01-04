require 'rails_helper'
require 'data_detector'

describe 'DataDetector specs' do
	describe '.detect_simple_json_type' do
		it 'detects boolean type' do
			expect(DataDetector.detect_json_simple_type(true)).to eq :boolean
			expect(DataDetector.detect_json_simple_type(false)).to eq :boolean
		end

		it 'detects number type' do
			expect(DataDetector.detect_json_simple_type(1)).to eq :number
			expect(DataDetector.detect_json_simple_type(1.412)).to eq :number
			expect(DataDetector.detect_json_simple_type(0)).to eq :number
		end

		it 'detects string type' do
			expect(DataDetector.detect_json_simple_type('what')).to eq :string
			expect(DataDetector.detect_json_simple_type('foo, right?')).to eq :string
			expect(DataDetector.detect_json_simple_type('')).to eq :string
		end

		it 'doesnt detect array type' do
			expect(DataDetector.detect_json_simple_type([])).to eq nil
			expect(DataDetector.detect_json_simple_type(['right'])).to eq nil
		end

		it 'doesnt detect object type' do
			expect(DataDetector.detect_json_simple_type({})).to eq nil
			expect(DataDetector.detect_json_simple_type({'a' => 10})).to eq nil
		end
	end

	describe '.is_ipv4_address' do
		it 'returns true for valid address' do
			expect(DataDetector.is_ipv4_address('10.7.16.69')).to be true
			expect(DataDetector.is_ipv4_address('192.0.0.1')).to be true
		end

		it 'returns false for invalid address' do
			expect(DataDetector.is_ipv4_address('10.7.16.69.15')).to be_falsy
			expect(DataDetector.is_ipv4_address('266.12.10.0')).to be_falsy
		end

		it 'handles gracefully non string values' do
			expect(DataDetector.is_ipv4_address([])).to be_falsy
			expect(DataDetector.is_ipv4_address(nil)).to be_falsy
			expect(DataDetector.is_ipv4_address(205)).to be_falsy
		end	
	end

	describe '.detect' do
		it 'detects json simple boolean' do
			expect(DataDetector.detect(true)).to eq :boolean
			expect(DataDetector.detect(false)).to eq :boolean
		end

		it 'detects json simple number' do
			expect(DataDetector.detect(12.51)).to eq :number
			expect(DataDetector.detect(0)).to eq :number
		end

		it 'detects json simple string' do
			expect(DataDetector.detect('12.51')).to eq :string
			expect(DataDetector.detect('0')).to eq :string
		end

		it 'detects ip type' do
			expect(DataDetector.detect('10.7.16.69')).to be :ip
			expect(DataDetector.detect('192.0.0.1')).to be :ip
		end

		it 'detects geolocation type' do
			expect(DataDetector.detect('geo(10;15)')).to be :geolocation
			expect(DataDetector.detect('geo(23.2566;90.5111)')).to be :geolocation
		end

		it 'detects array type' do
			expect(DataDetector.detect([1, 2])).to be :array
			expect(DataDetector.detect(['a', 'b'])).to be :array
		end
	end
end
