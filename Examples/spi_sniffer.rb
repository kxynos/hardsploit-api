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
require_relative '../HardsploitAPI/Core/HardsploitAPI'
require_relative '../HardsploitAPI/Modules/SPI_SNIFFER/HardsploitAPI_SPI_SNIFFER'

def callbackInfo(receiveData)
	#print receiveData  + "\n"
end

def callbackData(receiveData)
	if receiveData != nil then
		puts "received #{receiveData.size}"
	  	p receiveData
	else
		puts "ISSUE BECAUSE DATA IS NIL"
	end
end

def callbackSpeedOfTransfert(receiveData)
	#puts "Speed : #{receiveData}"
end

def callbackProgress(percent:,startTime:,endTime:)
	print "\r\e[#{31}mUpload of FPGA firmware in progress : #{percent}%\e[0m"
	#puts "Progress : #{percent}%  Start@ #{startTime}  Stop@ #{endTime}"
	#puts "Elasped time #{(endTime-startTime).round(4)} sec"
end

puts " ** Hardsploit SPI sniffer ** "

case ARGV[0]
when "-h", "--help"
	puts "[!] Usage: ruby #{$0} [nofirmware| -nf | --nf | -h]"
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
	puts "[-] USB ERRROR              "
	exit(false)
end
HardsploitAPI.instance.getAllVersions

interactive = true
while opt = ARGV.shift do
	puts case opt
		when "-ni" , "--ni" then
			interactive = false
			puts "[!] Not interactive"
		when "-nf" , "--nf", "nofirmware" then
			puts "[!] No FPGA firmware loaded (not always needed)"
		else 
			puts "[!] Loading SPI sniffer firmware loaded to FPGA"
			HardsploitAPI.instance.loadFirmware("SPI_SNIFFER")
		end
end

@spi = HardsploitAPI_SPI_SNIFFER.new(mode:0,sniff:HardsploitAPI::SPISniffer::MOSI)  # MISO MOSI MISO_MOSI
puts "[+] SPI Sniffing will start now. "
sleep(0.5)
def spiCustomCommand
	i = '.'
	while 1
		i == "." ? i = ".." : i = "." #just to have a toggle in console to keep alive the console
		begin
			result = @spi.spi_receive_available_data

			#if half a simple array, if fullduplex  first item -> an array of MISO  and second array -> an array of MOSI
			case @spi.sniff
			when HardsploitAPI::SPISniffer::MISO
				puts "MISO : #{result}"
			when HardsploitAPI::SPISniffer::MOSI
				puts "MOSI : #{result}"
			else
				puts "MOSI : #{result[0]}"
				puts "MISO : #{result[1]}"
			end

			rescue HardsploitAPI::ERROR::HARDSPLOIT_NOT_FOUND
				puts "Hardsploit not found"
			rescue HardsploitAPI::ERROR::USB_ERROR
				puts i
				#Ignore time out because we read in continous
			rescue SystemExit, Interrupt
				puts "[!] Ended by user "
				exit
		end
	end
 end

while true
	if !interactive then
		spiCustomCommand
		break
	else
		puts "[!] Sniffing starts after pressing the key i. "

	end
	char = STDIN.getch
	puts char
	if char ==  "\u0003"
		puts "[+] Finished"
		exit

	elsif  char  == "i" then
			spiCustomCommand
	elsif  char  == "p" then
			HardsploitAPI.instance.loadFirmware("SPI")
	end
end
