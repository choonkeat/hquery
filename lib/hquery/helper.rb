require 'sha1'

module Hquery
  module Helper
    def make_uri_absolutely_unique(http_host_with_port, path, unique = nil)
      unique ||= SHA1.hexdigest(IO.read(File.join(Rails.root, 'public', path)))
      URI.join(http_host_with_port, path + '?' + unique).to_s
    end
  end
end
