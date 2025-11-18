# ABOUTME: Capybara configuration for system tests
# ABOUTME: Sets up Selenium driver and screenshot capture on failures
require 'capybara/rspec'

RSpec.configure do |config|
  config.before(:each, type: :system) do |example|
    # Use rack_test for non-JS tests (faster, no browser needed)
    # Use selenium with headless chrome for JS tests (requires Chrome installed)
    if example.metadata[:js]
      driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
    else
      driven_by :rack_test
    end
  end
end

# Configure Capybara
Capybara.configure do |config|
  # Save screenshots in tmp/screenshots
  config.save_path = Rails.root.join('tmp', 'screenshots')

  # Automatically save screenshots on failure
  config.automatic_label_click = true

  # Wait up to 5 seconds for elements to appear
  config.default_max_wait_time = 5
end

# Register Chrome driver (for when Chrome is available)
Capybara.register_driver :selenium_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Take screenshots on test failure (only for selenium tests)
RSpec.configure do |config|
  config.after(:each, type: :system) do |example|
    if example.exception && example.metadata[:js]
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"
      screenshot_path = File.join(Capybara.save_path, screenshot_name)

      page.save_screenshot(screenshot_path) if page.driver.browser.respond_to?(:save_screenshot)
      puts "\n  Screenshot saved to #{screenshot_path}"
    end
  end
end
