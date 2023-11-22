require 'selenium-webdriver'
require 'webdrivers'
require 'fileutils'

module WebsiteChecker
  module_function

  TEXT_TO_LOOK_FOR = "'4 unavailable videos are hidden'"
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
        logger "Checking for text: #{TEXT_TO_LOOK_FOR}... at URL: #{URL_TO_CHECK}"

        driver.navigate.refresh
        wait.until { driver.execute_script("return document.readyState") == "complete" }
        current_state = driver.page_source.include?("4 unavailable videos are hidden")

        if current_state != previous_state
          logger("Change detected for text: #{TEXT_TO_LOOK_FOR}... at URL: #{URL_TO_CHECK}", true)
          previous_state = current_state
        else
          logger("No changes detected for text: #{TEXT_TO_LOOK_FOR}... at URL: #{URL_TO_CHECK}")
        end

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

    if change_detected && mac_os?
      current_time = time_now
      if current_time - $last_say_time > 300 #
        `say Change detected!`
        $last_say_time = current_time
      end
    end
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
    WAIT_TIME
  end


  def mac_os?
    RUBY_PLATFORM =~ /darwin/
  end
end

if __FILE__ == $PROGRAM_NAME
  WebsiteChecker.make_log_dir_unless_exists
  WebsiteChecker.logger("Start checking for text: #{WebsiteChecker::TEXT_TO_LOOK_FOR}... at URL: #{WebsiteChecker::URL_TO_CHECK}")
  WebsiteChecker.logger("Log file: #{WebsiteChecker::log_file_path}")
  WebsiteChecker.check_for_text
end


