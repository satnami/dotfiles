require "uri"
require "time"
require "net/http"
require 'nokogiri'
require 'date'

today = Date.today
formatted_date = today.strftime("%A %d %B %Y")

url = URI("https://www.islamiskaforbundet.se/wp-content/plugins/bonetider/Bonetider_Widget.php")
https = Net::HTTP.new(url.host, url.port)
https.use_ssl = true

request = Net::HTTP::Post.new(url)
form_data = [['ifis_bonetider_widget_city', 'Stockholm, SE'],['ifis_bonetider_widget_date', formatted_date]]
request.set_form form_data, 'multipart/form-data'
response = https.request(request)
parsed_data = Nokogiri::HTML.parse(response.read_body).css('li')

now = Time.now
current_prayer=""
next_prayer=""

prayers = {}
parsed_data.each_with_index do |item, index| 
  prayers[item.children[0].to_s] = Time.parse(item.children[1].text) 
  if(now < prayers[item.children[0].to_s] &&  next_prayer=="")
    #puts  prayers[item.children[0].to_s]
    next_prayer = item.children[0].to_s
    current_prayer = index==0 ? parsed_data[parsed_data.length-1].children[0].to_s : parsed_data[index-1].children[0].to_s
  end
end

#prayers.each {|prayer| puts prayer}
#puts
puts "Now: Time #{now}"
puts "Current: #{current_prayer} #{prayers[current_prayer]}"
puts "Next: #{next_prayer} #{prayers[next_prayer]}"
