#!/usr/bin/env ruby
#
# Copyright 2015 Changli Gao <xiaosuo@gmail.com>
#

require 'json'
require 'net/http'
require 'date'

$wind_angle_to_icon = [
  [(22.5...67.5),   '↙'],
  [(67.5...112.5),  '←'],
  [(112.5...157.5), '↖'],
  [(157.5...202.5), '↑'],
  [(202.5...247.5), '↗'],
  [(247.5...292.5), '→'],
  [(292.5...337.5), '↘'],
  [(0...360),       '↓']
]

$weather_icon = {
  "unknown" => [
    "    .-.      ",
    "     __)     ",
    "    (        ",
    "     `-’     ",
    "      •      "],
  "sunny" => [
    "\033[38;5;226m    \\   /    \033[0m",
    "\033[38;5;226m     .-.     \033[0m",
    "\033[38;5;226m  ― (   ) ―  \033[0m",
    "\033[38;5;226m     `-’     \033[0m",
    "\033[38;5;226m    /   \\    \033[0m"],
  "partlyCloudy" => [
    "\033[38;5;226m   \\  /\033[0m      ",
    "\033[38;5;226m _ /\"\"\033[38;5;250m.-.    \033[0m",
    "\033[38;5;226m   \\_\033[38;5;250m(   ).  \033[0m",
    "\033[38;5;226m   /\033[38;5;250m(___(__) \033[0m",
    "             "],
  "cloudy" => [
    "             ",
    "\033[38;5;250m     .--.    \033[0m",
    "\033[38;5;250m  .-(    ).  \033[0m",
    "\033[38;5;250m (___.__)__) \033[0m",
    "             "],
  "veryCloudy" => [
    "             ",
    "\033[38;5;240;1m     .--.    \033[0m",
    "\033[38;5;240;1m  .-(    ).  \033[0m",
    "\033[38;5;240;1m (___.__)__) \033[0m",
    "             "],
  "lightShowers" => [
    "\033[38;5;226m _`/\"\"\033[38;5;250m.-.    \033[0m",
    "\033[38;5;226m  ,\\_\033[38;5;250m(   ).  \033[0m",
    "\033[38;5;226m   /\033[38;5;250m(___(__) \033[0m",
    "\033[38;5;111m     ‘ ‘ ‘ ‘ \033[0m",
    "\033[38;5;111m    ‘ ‘ ‘ ‘  \033[0m"],
  "heavyShowers" => [
    "\033[38;5;226m _`/\"\"\033[38;5;240;1m.-.    \033[0m",
    "\033[38;5;226m  ,\\_\033[38;5;240;1m(   ).  \033[0m",
    "\033[38;5;226m   /\033[38;5;240;1m(___(__) \033[0m",
    "\033[38;5;21;1m   ‚‘‚‘‚‘‚‘  \033[0m",
    "\033[38;5;21;1m   ‚’‚’‚’‚’  \033[0m"],
  "lightSnowShowers" => [
    "\033[38;5;226m _`/\"\"\033[38;5;250m.-.    \033[0m",
    "\033[38;5;226m  ,\\_\033[38;5;250m(   ).  \033[0m",
    "\033[38;5;226m   /\033[38;5;250m(___(__) \033[0m",
    "\033[38;5;255m     *  *  * \033[0m",
    "\033[38;5;255m    *  *  *  \033[0m"],
  "heavySnowShowers" => [
    "\033[38;5;226m _`/\"\"\033[38;5;240;1m.-.    \033[0m",
    "\033[38;5;226m  ,\\_\033[38;5;240;1m(   ).  \033[0m",
    "\033[38;5;226m   /\033[38;5;240;1m(___(__) \033[0m",
    "\033[38;5;255;1m    * * * *  \033[0m",
    "\033[38;5;255;1m   * * * *   \033[0m"],
  "lightSleetShowers" => [
    "\033[38;5;226m _`/\"\"\033[38;5;250m.-.    \033[0m",
    "\033[38;5;226m  ,\\_\033[38;5;250m(   ).  \033[0m",
    "\033[38;5;226m   /\033[38;5;250m(___(__) \033[0m",
    "\033[38;5;111m     ‘ \033[38;5;255m*\033[38;5;111m ‘ \033[38;5;255m* \033[0m",
    "\033[38;5;255m    *\033[38;5;111m ‘ \033[38;5;255m*\033[38;5;111m ‘  \033[0m"],
  "thunderyShowers" => [
    "\033[38;5;226m _`/\"\"\033[38;5;250m.-.    \033[0m",
    "\033[38;5;226m  ,\\_\033[38;5;250m(   ).  \033[0m",
    "\033[38;5;226m   /\033[38;5;250m(___(__) \033[0m",
    "\033[38;5;228;5m    ⚡\033[38;5;111;25m‘ ‘\033[38;5;228;5m⚡\033[38;5;111;25m‘ ‘ \033[0m",
    "\033[38;5;111m    ‘ ‘ ‘ ‘  \033[0m"],
  "thunderyHeavyRain" => [
    "\033[38;5;240;1m     .-.     \033[0m",
    "\033[38;5;240;1m    (   ).   \033[0m",
    "\033[38;5;240;1m   (___(__)  \033[0m",
    "\033[38;5;21;1m  ‚‘\033[38;5;228;5m⚡\033[38;5;21;25m‘‚\033[38;5;228;5m⚡\033[38;5;21;25m‚‘   \033[0m",
    "\033[38;5;21;1m  ‚’‚’\033[38;5;228;5m⚡\033[38;5;21;25m’‚’   \033[0m"],
  "thunderySnowShowers" => [
    "\033[38;5;226m _`/\"\"\033[38;5;250m.-.    \033[0m",
    "\033[38;5;226m  ,\\_\033[38;5;250m(   ).  \033[0m",
    "\033[38;5;226m   /\033[38;5;250m(___(__) \033[0m",
    "\033[38;5;255m     *\033[38;5;228;5m⚡\033[38;5;255;25m *\033[38;5;228;5m⚡\033[38;5;255;25m * \033[0m",
    "\033[38;5;255m    *  *  *  \033[0m"],
  "lightRain" => [
    "\033[38;5;250m     .-.     \033[0m",
    "\033[38;5;250m    (   ).   \033[0m",
    "\033[38;5;250m   (___(__)  \033[0m",
    "\033[38;5;111m    ‘ ‘ ‘ ‘  \033[0m",
    "\033[38;5;111m   ‘ ‘ ‘ ‘   \033[0m"],
  "heavyRain" => [
    "\033[38;5;240;1m     .-.     \033[0m",
    "\033[38;5;240;1m    (   ).   \033[0m",
    "\033[38;5;240;1m   (___(__)  \033[0m",
    "\033[38;5;21;1m  ‚‘‚‘‚‘‚‘   \033[0m",
    "\033[38;5;21;1m  ‚’‚’‚’‚’   \033[0m"],
  "lightSnow" => [
    "\033[38;5;250m     .-.     \033[0m",
    "\033[38;5;250m    (   ).   \033[0m",
    "\033[38;5;250m   (___(__)  \033[0m",
    "\033[38;5;255m    *  *  *  \033[0m",
    "\033[38;5;255m   *  *  *   \033[0m"],
  "heavySnow" => [
    "\033[38;5;240;1m     .-.     \033[0m",
    "\033[38;5;240;1m    (   ).   \033[0m",
    "\033[38;5;240;1m   (___(__)  \033[0m",
    "\033[38;5;255;1m   * * * *   \033[0m",
    "\033[38;5;255;1m  * * * *    \033[0m"],
  "lightSleet" => [
    "\033[38;5;250m     .-.     \033[0m",
    "\033[38;5;250m    (   ).   \033[0m",
    "\033[38;5;250m   (___(__)  \033[0m",
    "\033[38;5;111m    ‘ \033[38;5;255m*\033[38;5;111m ‘ \033[38;5;255m*  \033[0m",
    "\033[38;5;255m   *\033[38;5;111m ‘ \033[38;5;255m*\033[38;5;111m ‘   \033[0m"],
  "fog" => [
    "             ",
    "\033[38;5;251m _ - _ - _ - \033[0m",
    "\033[38;5;251m  _ - _ - _  \033[0m",
    "\033[38;5;251m _ - _ - _ - \033[0m",
    "             "]
}

$weather_id_to_desc = [
  [[800], 'sunny'],
  [[801], 'partlyCloudy'],
  [[802], 'cloudy'],
  [[803, 804], 'veryCloudy'],
  [[620, 621], 'lightSnowShowers'],
  [[622], 'heavySnowShowers'],
  [[612], 'lightSleetShowers'],
  [[211], 'thunderyShowers'],
  [[201, 202], 'thunderyHeavyRain'],
  [[500, 501, 521], 'lightRain'],
  [[502, 503, 504, 522], 'heavyRain'],
  [[600, 601], 'lightSnow'],
  [[602], 'heavySnow'],
  [[611], 'lightSleet'],
  [[200], 'fog'],
]

$temp_color = %w{27 39 51 49 47 82 190 154 214 220}
$wind_color = %w{82 118 154 190 226 220 214 208 202}

$edge = {
  :left => {
    :top => {
      :left => '┌',
      :center => ''
    },
    :middle => {
      :left => '├',
      :center => ''
    },
    :bottom => {
      :left => '└',
      :center => ''
    },
    :vertical => {
      :left => '│',
      :center => ''
    }
  },
  :right => {
    :top => {
      :right => '┐',
      :center => '┬'
    },
    :middle => {
      :right => '┤',
      :center => '┼'
    },
    :bottom => {
      :right => '┘',
      :center => '┴'
    }
  }
}

$cell_len = 30

class OpenWeatherMap
  def initialize(city = 'beijing')
    @city = city
  end

  def get_data(days)
    uri = URI('http://api.openweathermap.org/data/2.5/forecast/daily')
    params = { :units => 'metric', :cnt => days, :q => @city }
    uri.query = URI.encode_www_form(params)
    JSON.parse(Net::HTTP.get(uri))
  end
end

def get_wind_icon(deg)
  $wind_angle_to_icon.each do |range, word|
    return "\033[1m#{word}\033[0m" if range.include?(deg)
  end
end

def get_weather_icon(id)
  $weather_id_to_desc.each do |range, word|
    return $weather_icon[word] if range.include?(id)
  end
  $weather_icon['unknown']
end

def render_wind_speed(speed)
  index = [(speed * 1.2).to_i, 8].min
  "\033[38;5;#{$wind_color[index]}m#{speed}\033[0m"
end

def render_temp(temp)
  index = [[((temp + 15) / 7).to_i, 0].max, 9].min
  "\033[38;5;#{$temp_color[index]}m#{temp}\033[0m"
end

def render_date(date)
  "\033[38;5;202m#{date}\033[0m"
end

def render_main(main)
  "\033[1;5;32m#{main}\033[0m"
end

def print_len(str)
  in_mode = false
  len = 0
  str.each_char do |c|
    if in_mode
      if c == 'm'
        in_mode = false
      end
    elsif c.ord == 033
      in_mode = true
    else
      len += 1
    end
  end
  len
end

def render_weather(data, left, right)
  cell = get_weather_icon(data['weather'][0]['id']).dup
  cell[0] += render_main(data['weather'][0]['main'])
  cell[1] += data['weather'][0]['description'][0,16]
  cell[2] += "#{get_wind_icon(data['deg'])} #{render_wind_speed(data['speed'])} m/s" 
  cell[3] += "#{render_temp(data['temp']['min'])} - #{render_temp(data['temp']['max'])} °C"
  cell[4] += "Humidity: #{data['humidity']}"
  cell = cell.map{|line| line + ' ' * ($cell_len - print_len(line))}
  caption_len = 10
  caption = render_date(DateTime.strptime(data['dt'].to_s, '%s').asctime[0,caption_len])

  prefix_space_len = ($cell_len - caption_len) / 2
  caption = ' ' * prefix_space_len + caption + ' ' * ($cell_len - caption_len - prefix_space_len)
  lines = []
  lines << $edge[:left][:top][left] + '─' * $cell_len + $edge[:right][:top][right]
  lines << $edge[:left][:vertical][left] + caption + '│'
  lines << $edge[:left][:middle][left] + '─' * $cell_len + $edge[:right][:middle][right]
  cell.each do |line|
    lines << $edge[:left][:vertical][left] + line + '│'
  end
  lines << $edge[:left][:bottom][left] + '─' * $cell_len + $edge[:right][:bottom][right]
end

screen_width = `stty size`.split(' ')[1].to_i
if screen_width < 32
  puts "Your window is too small to show a cell"
  exit(1)
end
days = 4

station = OpenWeatherMap.new(ARGV.size > 0 ? ARGV[0] : 'beijing')
data = station.get_data(days)
city = data['city']
puts "\n\033[38;5;202mWeather for City: \033[0m\033[1;5;32m#{city['name']} #{city['country']}\033[0m\n\n"
list = data['list']
lines = []
width = $cell_len + 2
left = :left
days.times do |i|
  right = (width + 31 > screen_width || i == days - 1) ? :right : :center 
  lines << render_weather(list[i], left, right)
  if right == :right
    lines.transpose.each do |line|
      puts line.join
    end
    lines = []
    width = $cell_len + 2
    left = :left
  else
    width += $cell_len + 1
    left = :center
  end
end
