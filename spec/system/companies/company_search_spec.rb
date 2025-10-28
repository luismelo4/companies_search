require 'rails_helper'

RSpec.describe 'Companies Search (without JavaScript)', type: :system do
  before do
    driven_by :rack_test
    Company.create!(coc_number: '12345678', company_name: 'Test Corp', city: 'Amsterdam')
    Company.create!(coc_number: '87654321', company_name: 'Another Corp', city: 'Rotterdam')
  end

  it 'allows searching for companies' do
    visit root_path
    
    expect(page).to have_content('Company Search')
    expect(page).to have_field('Search by company name, city, or CoC number...')
    
    # Test basic form submission (without JavaScript)
    fill_in 'Search by company name, city, or CoC number...', with: 'Test'
    
    # Test that the clear button is present (it has an icon, not text)
    expect(page).to have_css('button[data-action="click->autocomplete#clear"]')
  end

  it 'shows company data on the page' do
    visit root_path
    
    # Test that companies are displayed on the main page
    expect(page).to have_content('Test Corp')
    expect(page).to have_content('Amsterdam')
    expect(page).to have_content('12345678')
  end
end
