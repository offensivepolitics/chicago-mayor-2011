require 'rubygems'
require 'fastercsv'
require 'nokogiri'
require 'open-uri'

## scrape election returns from chicagoelections.com
## main page has ward level results (1-50), detail pages have precinct results
## http://www.chicagoelections.com/wdlevel3.asp?elec_code=25
base_titles = ["total_votes", "turnout_pct", "emanuel_count", "emanuel_pct", "delvalle_count", "delvalle_pct", 
             "braun_count", "braun_pct", "chico_count","chico_pct", "watkins_count", "watkins_pct", "walls_count", "walls_pct"]
ward_csv = FasterCSV.open("wards.csv", "w")
ward_csv << ["ward"] + base_titles

precinct_csv = FasterCSV.open("precincts.csv", "w")
precinct_csv << ["ward", "precinct"] + base_titles

# load the master ward list from a local file so we dont have to do a POST to the server to grab just the mayoral results
doc = Nokogiri::HTML(open("wards.html"))

doc.xpath("//table[1]/tr").each do |row|
  cells = row.xpath("td")
  ward_link = cells[0].xpath("p/font/b/a")
  # skip over header rows
  next unless ward_link.size == 1
  
  ward_number = ward_link.inner_text
  ward_url = "http://www.chicagoelections.com/" + ward_link.first["href"]
  values =  cells[1..13].map { |c| c.inner_text.strip.sub(/%/,"") }
  ward_csv << [ward_number] + values
  
  pctdoc = Nokogiri::HTML(open(ward_url))
  pctdoc.xpath("//table[1]/tr").each do |prow|
    cells = prow.xpath("td")
    next unless cells.size == 14 && cells[0].inner_text =~ /\d+/
    precinct_csv << [ward_number] + cells.map {|c| c.inner_text.strip.sub(/%/,'') }
  end
end

precinct_csv.close
ward_csv.close