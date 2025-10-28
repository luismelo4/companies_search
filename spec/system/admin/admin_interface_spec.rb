require 'rails_helper'

RSpec.describe 'Admin Interface', type: :system do
  before do
    driven_by :rack_test
    Company.create!(coc_number: '12345678', company_name: 'Test Corp', city: 'Amsterdam')
  end

  it 'displays admin dashboard' do
    visit admin_path
    
    expect(page).to have_content('Admin Panel - Company Import')
    expect(page).to have_content('Total Companies: 1')
    expect(page).to have_field('csv_file')
    expect(page).to have_button('Import CSV')
  end

  it 'shows clear data functionality' do
    visit admin_path
    
    expect(page).to have_content('Database Actions')
    expect(page).to have_content('Warning: This will permanently delete all company data')
  end
end
