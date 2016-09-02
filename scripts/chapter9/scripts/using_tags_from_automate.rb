unless $evm.execute('category_exists?', 'data_centre')
  $evm.execute('category_create',
                    :name => 'data_centre',
                    :single_value => false,
                    :perf_by_tag => false,
                    :description => "Data Centre")
end


unless $evm.execute('tag_exists?', 'data_centre', 'london')
  $evm.execute('tag_create', 'data_centre', :name => 'london', :description => 'London East End')
end


vm = $evm.root['vm']
vm.tag_unassign("data_center/paris")


ci_owner = 'engineering'
groups = $evm.vmdb(:miq_group).find(:all)
groups.each do |group|
  if group.tagged_with?("department", ci_owner)
    $evm.log("info", "Group #{group.description} is tagged")
  end
end


group_tags = group.tags


all_department_tags = group.tags(:department)
first_department_tag = group.tags(:department).first


tag = "/managed/department/legal"
hosts = $evm.vmdb(:host).find_tagged_with(:all => tag, :ns => "*")


tag = '/department/engineering'
[:vm_or_template, :host, :ems_cluster, :storage].each do |service_object|
  these_objects = $evm.vmdb(service_object).find_tagged_with(:all => tag, :ns => "/managed")
  these_objects.each do |this_object|
    service_model_class = "#{this_object.method_missing(:class)}".demodulize
    $evm.log("info", "#{service_model_class}: #{this_object.name}")
  end
end


categories = $evm.vmdb('classification').find(:all, :conditions => ["parent_id = 0"])
categories.each do |category|
  $evm.log(:info, "Found category: #{category.name} (#{category.description})")
end


$evm.vmdb(:classification).categories.each do |category|
  $evm.log(:info, "Found category: #{category.name} (#{category.description})")
end


classification = $evm.vmdb(:classification).find_by_name('cost_centre')
cost_centre_tags = {}
$evm.vmdb(:classification).find_all_by_parent_id(classification.id).each do |tag|
  cost_centre_tags[tag.name] = tag.description
end


department_classification = $evm.vmdb(:classification).find_by_name('department')
tag = $evm.vmdb('classification').find(:first, :conditions => ["parent_id = ? AND description = ?", department_classification.id, 'Systems Engineering'])
tag_name = tag.name


tag = $evm.vmdb(:classification).find_by_name('department/hr')


require 'rest-client'
require 'json'
require 'openssl'
require 'base64'

begin

  def rest_action(uri, verb, payload=nil)
    headers = {
      :content_type  => 'application/json',
      :accept        => 'application/json;version=2',
      :authorization => "Basic #{Base64.strict_encode64("#{@user}:#{@passwd}")}"
    }
    response = RestClient::Request.new(
      :method      => verb,
      :url         => uri,
      :headers     => headers,
      :payload     => payload,
      verify_ssl: false
    ).execute
    return JSON.parse(response.to_str) unless response.code.to_i == 204
  end
  
  servername   = $evm.object['servername']
  @username    = $evm.object['username']
  @password    = $evm.object.decrypt('password')

  uri_base = "https://#{servername}/api/"
  
  category = $evm.vmdb(:classification).find_by_name('network_location')
  rest_return = rest_action("#{uri_base}/categories/#{category.id}", :delete)
  exit MIQ_OK
rescue RestClient::Exception => err
  unless err.response.nil?
    $evm.log(:error, "REST request failed, code: #{err.response.code}")
    $evm.log(:error, "Response body:\n#{err.response.body.inspect}")
  end
  exit MIQ_STOP
rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end