# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
# frozen_string_literal: true

# require 'webmock/rspec'
require 'capybara/rspec'
require 'webdrivers/chromedriver'
require 'selenium-webdriver'
require 'rspec/retry'
require 'rspec/testrail'
require 'yaml'
require 'secret_keys'

Selenium::WebDriver.logger.output = false
Webdrivers::Chromedriver.required_version = '122.0.6261.69' #'114.0.5735.90'

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--ignore-certificate-errors')
options.add_argument('--disable-notifications')
options.add_argument('--enable-features=WebNotifications')
options.add_argument('--disable-dev-shm-usage')
options.add_argument('--headless')

Capybara.register_driver :chrome_mobile do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :chrome_mobile
Capybara.default_max_wait_time = 15 # 15 seconds

RSPEC_ROOT = File.dirname __FILE__

RSpec.configure do |config|
  config.include Capybara::DSL
  config.verbose_retry = true
  config.display_try_failure_messages = true

  default_retry_count = ENV['RSPEC_RETRY_DEFAULT_RETRY_COUNT'] || 1
  config.default_retry_count = default_retry_count

  # retry only on feature or js specs
  config.around :each, :js do |ex|
    feature_spec_retry_count = ENV['CI'] ? 3 : default_retry_count
    ex.run_with_retry retry: feature_spec_retry_count
  end
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.before :all do
    if ENV['MASTER_KEY']
      credentials = SecretKeys.new("credentials.yml", ENV['MASTER_KEY'])

      RSpec::Testrail.init  project_id: 6,
                            suite_id: 22,
                            url: 'https://liscio.testrail.io',
                            user: credentials['testrail_user'],
                            password: credentials['testrail_password'],
                            run_name: `git rev-parse --abbrev-ref HEAD`,
                            run_description: `git rev-parse HEAD`.strip
    end
  end

  config.after :example, testrail_id: proc { |value| !value.nil? } do |example|
    RSpec::Testrail.process(example) if ENV['MASTER_KEY']
  end
end