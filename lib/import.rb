module Distiller
  class Import

    extend Distiller::Helpers

    def self.localities
      dataset_name = "Office for National Statistics Index of Place Names 2012 (E+W)"
      dataset_url = "https://github.com/OpenAddressesUK/IPN_2012/blob/master/IPN2012.csv?raw=true"
      downloaded_at = DateTime.now
      description_url = "https://geoportal.statistics.gov.uk/geoportal/catalog/search/resource/details.page?uuid=%7BCDE30768-6419-4730-B434-B8B46BF9CBB1%7D"

      ipn = HTTParty.get(dataset_url).parsed_response

      CSV.parse(ipn, headers: true) do |row|
        ll = en_to_ll(row['GRIDGB1E'], row['GRIDGB1N'])
        Locality.create(
                          name: row['PLACE12NM'].chomp(")"),
                          authority: get_authority(row),
                          lat_lng: [ll[:lat], ll[:lng]],
                          easting_northing: [row['GRIDGB1N'], row['GRIDGB1E']],
                          provenance: create_provenance(dataset_url, dataset_name, downloaded_at, description_url)
                         )
      end

    end

    def self.get_authority(row)
      authority = [
        row['NMD12CD'],
        row['UA12CD'],
        row['MD12CD'],
        row['LONB12CD']
      ].reject! { |a| a.blank? }

      return authority.first if authority.count == 1
    end

    def self.towns
      dataset_name = "Address Base Towns"
      dataset_url = "https://en.wikipedia.org/wiki/List_of_post_towns_in_the_United_Kingdom"
      downloaded_at = DateTime.now
      description_url = "https://en.wikipedia.org/wiki/List_of_post_towns_in_the_United_Kingdom"

      CSV.parse(File.read("data/towns.csv"), headers:true) do |row|
        Town.create(
          area: row[1],
          name: row[0],
          provenance: create_provenance(dataset_url, dataset_name, downloaded_at, description_url))
        end
    end

    def self.postcodes
      dataset_name = "ONS Postcode Directory (UK) Aug 2014"
      dataset_url = "https://geoportal.statistics.gov.uk/Docs/PostCodes/ONSPD_AUG_2014_csv.zip"
      downloaded_at = DateTime.now
      description_url = "https://geoportal.statistics.gov.uk/geoportal/catalog/search/resource/details.page?uuid=%7B473A5770-FB1B-4C1A-AEEC-5DC056E5EC7F%7D"

      zip = Tempfile.new("postcodes.zip")
      zip.binmode
      zip.write HTTParty.get(dataset_url).parsed_response
      zip.close

      Zip::File.open(zip.path)do |zip_file|
        entry = zip_file.glob('Data/*.csv').first
        CSV.parse(entry.get_input_stream.read, headers: true) do |row|
          pc = UKPostcode.new(row['pcd'])
          ll = en_to_ll(row['oseast1m'], row['osnrth1m'])
          Postcode.create(
                          name: pc.norm,
                          area: pc.area,
                          outcode: pc.outcode,
                          incode: pc.incode,
                          easting: row['oseast1m'],
                          northing: row['osnrth1m'],
                          introduced: parse_date(row['dointr']),
                          terminated: parse_date(row['doterm']),
                          authority: row['oslaua'],
                          lat_lng: [ll[:lat], ll[:lng]],
                          easting_northing: [row['osnrth1m'], row['oseast1m']],
                          provenance: create_provenance(dataset_url, dataset_name, downloaded_at, description_url)
                         )
        end
      end

    end

    def self.streets
      dataset_name = "OS Locator"
      description_url = "http://www.ordnancesurvey.co.uk/business-and-government/products/os-locator.html"
      dataset_url = "https://github.com/OpenAddressesUK/OS_Locator/blob/gh-pages/OS_Locator2014_2_OPEN_xa.txt?raw=true"
      downloaded_at = DateTime.now


      CSV.open("data/streets.6.csv",headers: true) do |street|
        streets = street.each
        streets.select do |row|
          Street.create(
            name: row[0],
            settlement: row[6],
            locality: row[5],
            authority: "",
            lat_lng: [row[1], row[2]],
            easting_northing: [row[4], row[3]],
            provenance: create_provenance(dataset_url, dataset_name, downloaded_at, description_url)
          )
          end
        end
    end

    def self.parse_date(date, format = "%Y%m")
      if !date.blank?
        DateTime.strptime(date, "%Y%m")
      end
    end

    def self.create_provenance(url, name, downloaded_at, description_url)
      {
        activity: {
          executed_at: DateTime.now,
          processing_scripts: "https://github.com/OpenAddressesUK/distiller",
          derived_from: [
            {
              name: name,
              type: "Source",
              urls: [
                url
              ],
              downloaded_at: downloaded_at,
              description_url: description_url,
              processing_script: "https://github.com/OpenAddressesUK/distiller/tree/#{current_sha}/lib/import.rb"
            }
          ]
        }
      }
    end
    
  end
end
