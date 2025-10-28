require 'rails_helper'
require 'csv'

RSpec.describe CompanyImportService do
  let(:temp_csv_file) { Tempfile.new(['test_companies', '.csv']) }
  
  after do
    temp_csv_file.close
    temp_csv_file.unlink
  end

  describe '.import_from_file' do
    context 'with valid CSV data' do
      before do
        CSV.open(temp_csv_file.path, 'w', col_sep: ';') do |csv|
          csv << ['coc_number', 'company_name', 'city']
          csv << ['12345678', 'Test Corp', 'Amsterdam']
          csv << ['87654321', 'Another Corp', 'Rotterdam']
        end
      end

      it 'imports companies successfully' do
        result = CompanyImportService.import_from_file(temp_csv_file.path)
        
        expect(result.success?).to be true
        expect(result.total_processed).to eq(2)
        expect(result.final_count).to eq(2)
        expect(result.duplicates_removed).to eq(0)
        expect(Company.count).to eq(2)
      end

      it 'creates companies in the database' do
        CompanyImportService.import_from_file(temp_csv_file.path)
        
        expect(Company.find_by(coc_number: '12345678')).to be_present
        expect(Company.find_by(coc_number: '87654321')).to be_present
      end
    end

    context 'with duplicate coc_numbers' do
      before do
        CSV.open(temp_csv_file.path, 'w', col_sep: ';') do |csv|
          csv << ['coc_number', 'company_name', 'city']
          csv << ['12345678', 'First Corp', 'Amsterdam']
          csv << ['12345678', 'Second Corp', 'Rotterdam']  # Duplicate
        end
      end

      it 'keeps the last occurrence of duplicates' do
        result = CompanyImportService.import_from_file(temp_csv_file.path)
        
        expect(result.total_processed).to eq(2)
        expect(result.duplicates_removed).to eq(1)
        expect(result.final_count).to eq(1)
        expect(Company.count).to eq(1)
        expect(Company.first.company_name).to eq('Second Corp')
      end
    end

    context 'with blank coc_number' do
      before do
        CSV.open(temp_csv_file.path, 'w', col_sep: ';') do |csv|
          csv << ['coc_number', 'company_name', 'city']
          csv << ['', 'Test Corp', 'Amsterdam']  # Blank coc_number
          csv << ['12345678', 'Valid Corp', 'Rotterdam']
        end
      end

      it 'skips rows with blank coc_number' do
        result = CompanyImportService.import_from_file(temp_csv_file.path)
        
        expect(result.total_processed).to eq(1)
        expect(Company.count).to eq(1)
        expect(Company.first.company_name).to eq('Valid Corp')
      end
    end

    context 'with buffered processing' do
      before do
        CSV.open(temp_csv_file.path, 'w', col_sep: ';') do |csv|
          csv << ['coc_number', 'company_name', 'city']
          # Create 1500 rows to test buffering (buffer size is 1000)
          1500.times do |i|
            csv << ["#{i.to_s.rjust(8, '0')}", "Company #{i}", "City #{i}"]
          end
        end
      end

      it 'processes large files in chunks' do
        result = CompanyImportService.import_from_file(temp_csv_file.path)
        
        expect(result.success?).to be true
        expect(result.total_processed).to eq(1500)
        expect(Company.count).to eq(1500)
      end
    end

    context 'with file errors' do
      it 'returns error result when file does not exist' do
        result = CompanyImportService.import_from_file('nonexistent.csv')
        
        expect(result.success?).to be false
        expect(result.error).to be_present
      end
    end

    context 'ImportResult' do
      describe '#success?' do
        it 'returns true when no error' do
          result = CompanyImportService::ImportResult.new
          expect(result.success?).to be true
        end

        it 'returns false when error present' do
          result = CompanyImportService::ImportResult.new(error: 'Test error')
          expect(result.success?).to be false
        end
      end

      describe '#success_message' do
        it 'returns formatted message with statistics' do
          result = CompanyImportService::ImportResult.new(
            total_processed: 100,
            duplicates_removed: 10,
            final_count: 90
          )
          
          message = result.success_message
          expect(message).to include('100')
          expect(message).to include('10')
          expect(message).to include('90')
        end
      end
    end
  end
end

