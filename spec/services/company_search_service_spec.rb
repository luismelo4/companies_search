require 'rails_helper'

RSpec.describe CompanySearchService do
  before do
    Company.create!(coc_number: '12345678', company_name: 'Beequip', city: 'Amsterdam')
    Company.create!(coc_number: '87654321', company_name: 'Test Corp', city: 'Amsterdam')
    Company.create!(coc_number: '11111111', company_name: 'Another Corp', city: 'Rotterdam')
  end

  describe '#call' do
    context 'when query is blank' do
      it 'returns empty array' do
        expect(CompanySearchService.new('').call).to eq([])
        expect(CompanySearchService.new(nil).call).to eq([])
      end
    end

    context 'when query is too short' do
      it 'returns empty array for single character' do
        expect(CompanySearchService.new('B').call).to eq([])
      end
    end

    context 'when query matches company names' do
      it 'returns suggestions with company names' do
        suggestions = CompanySearchService.new('Bee').call
        expect(suggestions.length).to be > 0
        expect(suggestions.first[:text]).to eq('Beequip')
        expect(suggestions.first[:type]).to eq('Company Name')
      end
    end

    context 'when query matches cities' do
      it 'returns suggestions with cities' do
        suggestions = CompanySearchService.new('Amster').call
        city_suggestions = suggestions.select { |s| s[:type] == 'City' }
        expect(city_suggestions.length).to be > 0
      end
    end

    context 'when query matches coc numbers' do
      it 'returns suggestions with coc numbers' do
        suggestions = CompanySearchService.new('12345').call
        coc_suggestions = suggestions.select { |s| s[:type] == 'CoC Number' }
        expect(coc_suggestions.length).to be > 0
      end
    end

    context 'when multiple matches exist' do
      it 'combines suggestions from all types' do
        suggestions = CompanySearchService.new('Amster').call
        types = suggestions.map { |s| s[:type] }.uniq
        expect(types.length).to be >= 1
      end

      it 'deduplicates by text value' do
        suggestions = CompanySearchService.new('Amster').call
        texts = suggestions.map { |s| s[:text] }
        expect(texts).to eq(texts.uniq)
      end

      it 'limits to MAX_SUGGESTIONS' do
        # Create more companies to test limit
        10.times do |i|
          Company.create!(
            coc_number: "9999999#{i}",
            company_name: "Test#{i}",
            city: "City#{i}"
          )
        end
        
        suggestions = CompanySearchService.new('Test').call
        expect(suggestions.length).to be <= CompanySearchService::MAX_SUGGESTIONS
      end
    end
  end
end

