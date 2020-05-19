#!/usr/bin/ruby
#===================================================
#  Coded by Konstantinos Xynos (2020)
#  Version: 1.0
#  Based on Hardsploit API - By Opale Security
#  www.opale-security.com || www.hardsploit.io
#  License: GNU General Public License v3
#  License URI: http://www.gnu.org/licenses/gpl.txt
#===================================================

#
# SPI I/O Pins on Hardsploit
# Assuming they are on default layout
#
# Pin A0 : Clock (CLK)
# Pin A1 : Cable Select (CS)
# Pin A2 : MOSI (SI)
# Pin A3 : MISO (SO)
#

require 'io/console'
require 'logger'
require_relative '../HardsploitAPI/Core/HardsploitAPI'
require_relative '../HardsploitAPI/Modules/SPI/HardsploitAPI_SPI'

$logFilePath = File.expand_path(File.dirname(__FILE__)) + "/hs_error.log"
$filepath = File.expand_path(File.dirname(__FILE__)) + "/hs_spi_export.bin"

$endTime_ = ''
$percent_prv = 0

@speeds = {
      '25.00' => 3,
      '18.75' => 4,
      '15.00' => 5,
      '12.50' => 6,
      '10.71' => 7,
      '9.38' => 8,
      '7.50' => 10,
      '5.00' => 15,
      '3.95' => 19,
      '3.00' => 25,
      '2.03' => 37,
      '1.00' => 75,
      '0.50' => 150,
      '0.29' => 255
    }

@chip_settings_ = {
      'spi_total_size' => 4194304,
    # 'spi_total_size' => 8388608,
      'start_address' => 0,
      'spi_mode' => 0,
      'spi_speed' => '15.00',
      'spi_command' => 3
    }

def select_export_file
    unless $filepath.nil?
      $file = File.open("#{$filepath}", 'w')
    end
    rescue Exception => msg
      logger = Logger.new($logFilePath)
      logger.error msg
end

def close_file
    unless $file.nil?
      $file.close
    end
    rescue Exception => msg
      logger = Logger.new($logFilePath)
      logger.error msg
end

def callbackInfo(receiveData)
	#print receiveData  + "\n"
end

def callbackData(receiveData)
	if receiveData != nil then
		#puts "received #{receiveData.size}"
	  	#p receiveData
		$file.write(receiveData.pack("c*"))
	else
		puts "[!] ISSUE BECAUSE DATA IS NIL"
	end
end

def callbackSpeedOfTransfert(receiveData)
	#puts "Speed : #{receiveData}"
end

def callbackProgress(percent:,startTime:,endTime:)
	if percent > $percent_prv
		$percent_prv = percent
		print "[+] Progress : #{percent}%  Start@ #{startTime}  Stop@ #{endTime} " + "\r"
		$stdout.flush
	end
	$endTime_ = "Elasped time #{(endTime-startTime).round(4)} sec"
#	puts "Elasped time #{(endTime-startTime).round(4)} sec"
end

puts " ** Hardsploit SPI export ** "

case ARGV[0]
when "-h", "--help"
	puts "[!] Usage: ruby #{$0} [nofirmware|-nf|-h|]"
	exit
end

HardsploitAPI.callbackInfo = method(:callbackInfo)
HardsploitAPI.callbackData = method(:callbackData)
HardsploitAPI.callbackSpeedOfTransfert = method(:callbackSpeedOfTransfert)
HardsploitAPI.callbackProgress = method(:callbackProgress)
HardsploitAPI.id = 0  # id of hardsploit 0 for the first one, 1 for the second etc

begin
  HardsploitAPI.instance

rescue HardsploitAPI::ERROR::HARDSPLOIT_NOT_FOUND
  puts "[-] HARDSPLOIT Not Found"
  exit(false)
rescue HardsploitAPI::ERROR::USB_ERROR
  # HardsploitAPI.reset_device_access
  puts "[-] USB ERRROR              "
  exit(false)
end

puts "[+] Number of hardsploit detected :#{HardsploitAPI.getNumberOfBoardAvailable}"
HardsploitAPI.instance.getAllVersions

case ARGV[0]
when "-nf" , "--nf", "nofirmware"
	puts "[!] No FPGA firmware loaded (not always needed)"
else 
  puts "[+] Loading SPI firmware onto HARDSPLOIT"
  HardsploitAPI.instance.loadFirmware("SPI")
  $percent_prv=0
  puts "\n" # add a new line 
end

begin

HardsploitAPI.callbackProgress = method(:callbackProgress)
select_export_file

@spi = HardsploitAPI_SPI.new(speed:@speeds[@chip_settings_['spi_speed']],mode:@chip_settings_['spi_mode'])

puts "[+] HARDSPLOIT SPI export started "
@spi.spi_Generic_Dump(readSpiCommand:@chip_settings_['spi_command'], startAddress:@chip_settings_['start_address'],stopAddress:@chip_settings_['spi_total_size']-1,sizeMax:@chip_settings_['spi_total_size'])

close_file

puts "\n[+] HARDSPLOIT SPI export completed successfully"
puts "[+] " + $endTime_ 
puts "[+] File saved in : " + $filepath 

rescue HardsploitAPI::ERROR::HARDSPLOIT_NOT_FOUND
  puts "[-] HARDSPLOIT Not Found\n"
  close_file
  exit(-1)
rescue HardsploitAPI::ERROR::USB_ERROR
  # HardsploitAPI.reset_device_access
  puts "[-] USB ERRROR              "
  close_file
  exit(-1)
rescue SystemExit, Interrupt
  puts "[!] Ended by user           "
  close_file
  # HardsploitAPI.reset_device_access
  exit(-42)
end
