require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'validations' do
    it 'validates presence of coc_number' do
      company = Company.new(company_name: 'Test Corp', city: 'Amsterdam')
      expect(company).not_to be_valid
      expect(company.errors[:coc_number]).to include("can't be blank")
    end

    it 'validates presence of company_name' do
      company = Company.new(coc_number: '12345678', city: 'Amsterdam')
      expect(company).not_to be_valid
      expect(company.errors[:company_name]).to include("can't be blank")
    end

    it 'validates presence of city' do
      company = Company.new(coc_number: '12345678', company_name: 'Test Corp')
      expect(company).not_to be_valid
      expect(company.errors[:city]).to include("can't be blank")
    end

    it 'validates uniqueness of coc_number' do
      Company.create!(coc_number: '12345678', company_name: 'Test Corp', city: 'Amsterdam')
      duplicate = Company.new(coc_number: '12345678', company_name: 'Another Corp', city: 'Rotterdam')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:coc_number]).to include('has already been taken')
    end
  end

  describe '.search' do
    before do
      Company.create!(coc_number: '12345678', company_name: 'Test Corp', city: 'Amsterdam')
      Company.create!(coc_number: '87654321', company_name: 'Another Corp', city: 'Rotterdam')
    end

    it 'returns companies matching company name' do
      results = Company.search('Test')
      expect(results.count).to eq(1)
      expect(results.first.company_name).to eq('Test Corp')
    end

    it 'returns companies matching city' do
      results = Company.search('Amsterdam')
      expect(results.count).to eq(1)
      expect(results.first.city).to eq('Amsterdam')
    end

    it 'returns companies matching coc_number' do
      results = Company.search('12345678')
      expect(results.count).to eq(1)
      expect(results.first.coc_number).to eq('12345678')
    end

    it 'returns empty result for no matches' do
      results = Company.search('NonExistent')
      expect(results.count).to eq(0)
    end

    it 'returns empty result for blank query' do
      results = Company.search('')
      expect(results.count).to eq(0)
    end
  end
end