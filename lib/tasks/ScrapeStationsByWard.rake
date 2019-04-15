namespace :gotv do
  desc "Get polling station list for a council and add ward details"
  task :scrape, [:council_code] do |t, args|
    args.with_defaults(:council_code => "E06000014")
    require 'postcodes_io'

    def find_polling_stations(council_code)
      endpoint_url = "https://wheredoivote.co.uk/api/beta/pollingstations.json?council_id=#{council_code}"
      stations = JSON.parse(open(endpoint_url).read)

      stations.map do |station|
        # some of the postcode fields are missing so scrape from address. credit https://www.regextester.com/93715
        postcode_regex = /\b((?:(?:gir)|(?:[a-pr-uwyz])(?:(?:[0-9](?:[a-hjkpstuw]|[0-9])?)|(?:[a-hk-y][0-9](?:[0-9]|[abehmnprv-y])?)))) ?([0-9][abd-hjlnp-uw-z]{2})\b/i
        station['postcode'] = station['address'][postcode_regex]
        station
      end
    end

    def find_wards(postcodes)
      pio = Postcodes::IO.new
      pio.lookup(postcodes).map do |result|
        result.info.nil? ?
            nil : # a couple of postcode don't seem to be found eg YO1 0RL and Y01 9TL (note zero)
            {
                :postcode => result.postcode,
                :ward_code => result.codes['admin_ward'],
                :ward_name => result.admin_ward
            }
      end
    end


    stations = find_polling_stations(args[:council_code])
    postcodes = stations.map {|station| station['postcode']}
    good_postcodes = postcodes - [nil] # eg '2nd Haxby & Wigginton Scout HQ, 9 York Road, Haxby', 'Mobile Unit, White Swan car park, York Road, Deighton' or 'Y032 9FY' (note zero instead of O)
    puts find_wards(good_postcodes)
  end
end