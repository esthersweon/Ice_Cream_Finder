require 'addressable/uri'
require 'json'
require 'launchy'
require 'rest-client'

def ask_current_location
  puts "Please input your current location:"
  location = gets.chomp
end

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

def nearby_locations(lat, lng)
  nearby_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "maps/api/place/nearbysearch/json",
    :query_values => {
      :key => "AIzaSyDSPEHKkyruYPzbSnAB4Bc7WOPMLljHnfY",
      :location => "#{lat}, #{lng}",
      :radius => "5000",
      :sensor => "false",
      :keyword => "ice cream",
      :rank_by => "distance"}
  ).to_s

  response = RestClient.get(nearby_url)
  results = JSON.parse(response)
  name = results["results"][0]["name"]
  lat_lng = results["results"][0]["geometry"]["location"]

  [name, lat_lng["lat"], lat_lng["lng"]]
end

def directions(origin, destination)
  directions_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "maps/api/directions/json",
    :query_values => {
      :origin => "#{origin["lat"]}, #{origin["lng"]}",
      :destination => "#{destination[1]}, #{destination[2]}",
      :sensor => "false",
      :mode => "walking"}
  ).to_s

  response = RestClient.get(directions_url)
  results = JSON.parse(response)
end


def print_directions(results, name)
  puts "Directions to #{name}"
  puts "Start Address: #{results["routes"][0]["legs"][0]["start_address"]}"
  puts
  steps = results["routes"][0]["legs"][0]["steps"]
  steps.each do |k, v|
    puts k["html_instructions"].gsub(/<.+?>/, " ").gsub("  ", " ")
    puts "for #{k["distance"]["text"]}"
  end
  puts
  puts "End Address: #{results["routes"][0]["legs"][0]["end_address"]}"
end

input_cl = ask_current_location
cl = current_location(input_cl)
dst = nearby_locations(cl["lat"], cl["lng"])
dir = directions(cl, dst)
print_directions(dir, dst[0])