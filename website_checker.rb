require 'selenium-webdriver'
require 'webdrivers'
require 'fileutils'

module WebsiteChecker
  module_function

  TEXT_TO_LOOK_FOR = "4 unavailable videos are hidden"
  URL_TO_CHECK = "https://www.youtube.com/playlist?list=PL2C01sMWT3BZLmZBMw26BqCP6cRyZDCQs"
  WAIT_TIME = 300

  def check_for_text
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless') # Run in headless mode

    begin
      driver = Selenium::WebDriver.for :chrome, options: options
      driver.get URL_TO_CHECK
      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      wait.until { driver.execute_script("return document.readyState") == "complete" }

      previous_state = driver.page_source.include?(TEXT_TO_LOOK_FOR)

      loop do
        logger "Checking for text: '#{TEXT_TO_LOOK_FOR}' at URL: #{URL_TO_CHECK}"

        driver.navigate.refresh
        wait.until { driver.execute_script("return document.readyState") == "complete" }
        current_state = driver.page_source.include?(TEXT_TO_LOOK_FOR)

        if current_state != previous_state
          `say Change detected!` if mac_os?
          logger("Change detected for text: #{TEXT_TO_LOOK_FOR}... at URL: #{URL_TO_CHECK}", true)
          previous_state = current_state
        else
          logger("No changes detected for text: '#{TEXT_TO_LOOK_FOR}' at URL: #{URL_TO_CHECK}")
        end

        logger "Waiting for #{wait_human_time} before checking again..."
        sleep(300)
      end
    ensure
      driver.quit
    end
  end

  def logger(message, change_detected = false)
    message = "#{time_now}: #{message}" #
    puts message
    File.open(log_file_path, "a") { |file| file.puts(message) }

  end

  def time_now
    Time.now.strftime('%Y-%m-%d %H:%M:%S')
  end

  def log_dir
    @_log_dir = File.join(File.dirname(__FILE__), 'logs')
  end

  def log_file_path
    @_log_file_path ||= File.join(log_dir, 'change_log.txt')
  end

  def make_log_dir_unless_exists
    FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
  end

  def wait_human_time
    format_duration(WAIT_TIME)
  end

  def format_duration(seconds)
    minutes = seconds / 60
    remaining_seconds = seconds % 60
    formatted_time = ""
    formatted_time += "#{minutes} minute#{'s' unless minutes == 1} " if minutes > 0
    formatted_time += "#{remaining_seconds} second#{'s' unless remaining_seconds == 1}" if remaining_seconds > 0
    formatted_time.strip
  end

  def mac_os?
    RUBY_PLATFORM =~ /darwin/
  end
end

if __FILE__ == $PROGRAM_NAME
  WebsiteChecker.make_log_dir_unless_exists
  WebsiteChecker.logger("Start checking for text: '#{WebsiteChecker::TEXT_TO_LOOK_FOR}' at URL: #{WebsiteChecker::URL_TO_CHECK}")
  WebsiteChecker.logger("Log file: #{WebsiteChecker::log_file_path}")
  WebsiteChecker.check_for_text
end
