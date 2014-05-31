require 'addressable/uri'
require 'json'
require 'launchy'
require 'rest-client'
require 'nokogiri'

def ask_current_location
  puts "Please input your current location:"
  address = gets.chomp
end

def ask_target
  puts "Please input what you are looking for:"
  target = gets.chomp
end

#Google Geocoding API
#REQUEST: "http://maps.googleapis.com/maps/api/geocode/output?parameters"
#Given address, returns latitute and longitude
def current_location(address)
  current_location_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "maps/api/geocode/json",
    :query_values => {
      :address => address,
      :sensor => "false"}
  ).to_s

  response = RestClient.get(current_location_url)
  results = JSON.parse(response)
  results["results"][0]["geometry"]["location"]
end

#Google Places API
#REQUEST: "https://maps.googleapis.com/maps/api/place/nearbysearch/output?parameters"
#Given latitude and longitude and search string, finds nearby matching locations
#Returns [name, lat, lng]
def nearby_locations(lat, lng, target)
  nearby_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "maps/api/place/nearbysearch/json",
    :query_values => {
      :key => "AIzaSyDSPEHKkyruYPzbSnAB4Bc7WOPMLljHnfY",
      :location => "#{lat}, #{lng}",
      :radius => "5000",
      :sensor => "false",
      :keyword => target,
      :rank_by => "distance"}
  ).to_s

  response = RestClient.get(nearby_url)
  results = JSON.parse(response)
  name = results["results"][0]["name"]
  lat_lng = results["results"][0]["geometry"]["location"]

  [name, lat_lng["lat"], lat_lng["lng"]]
end

#Google Directions API
#REQUEST: "http://maps.googleapis.com/maps/api/directions/output?parameters"
#Given two pairs of latitude and longitude, returns directions
def directions(origin_lat_lng, destination_name_lat_lng)
  directions_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "maps/api/directions/json",
    :query_values => {
      :origin => "#{origin_lat_lng["lat"]}, #{origin_lat_lng["lng"]}",
      :destination => "#{destination_name_lat_lng[1]}, #{destination_name_lat_lng[2]}",
      :sensor => "false",
      :mode => "walking"}
  ).to_s

  response = RestClient.get(directions_url)
  results = JSON.parse(response)
end

def print_directions(results, name)
  puts "Directions to #{name}"
  puts
  puts "Start Address: #{results["routes"][0]["legs"][0]["start_address"]}"
  puts
  steps = results["routes"][0]["legs"][0]["steps"]
  steps.each do |key, value|
      puts Nokogiri::HTML(key["html_instructions"]).text.gsub("Destination", ". Destination") + "."
      puts "for #{key["distance"]["text"]}"
  end
  puts
  puts "End Address: #{results["routes"][0]["legs"][0]["end_address"]}"
end

input_cl = ask_current_location
input_target = ask_target
cl_lat_lng = current_location(input_cl)
dst_name_lat_lng = nearby_locations(cl_lat_lng["lat"], cl_lat_lng["lng"], input_target)
dir = directions(cl_lat_lng, dst_name_lat_lng)
print_directions(dir, dst_name_lat_lng[0])
