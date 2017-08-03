#
# Cookbook:: azure_notification
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

#
# variables
#
node_name = Chef.run_context.node.name.to_s
azure_folder = node["azure"]["folder"]
file_content = node["file"]["content"]
file_name = node["file"]["name"]
azure_command = <<-SCRIPT
cd C:\\chef\\AzureUploader
.\\AzureUploader.exe
SCRIPT

#
# Upload file result job.txt
#
ruby_block 'File result' do
  block do
    Chef::Log.info(file_content)
    file = File.new("C:\\chef\\#{file_name}.txt", 'w')
    file.write(file_content)
    file.close
  end
end

windows_zipfile 'C:\chef\AzureUploader' do
  source 'https://evachef.blob.core.windows.net/resources/installer/AzureUploader.zip'
  action :unzip
  not_if { File.directory?('C:\chef\AzureUploader') }
end

template 'Settings' do
  path 'C:\chef\AzureUploader\settings.config'
  source 'settings.erb'
  variables({
    :node_name => node_name,
    :azure_folder => azure_folder
  })
end

ruby_block 'AzureUploader' do
  block do
    upload = powershell_out!(azure_command)
    Chef::Log.info("\n#{upload.stdout.chop}")
  end
end

ruby_block 'Delete .zip File Chef' do
  block do
    Dir.foreach('C:\chef') do |zipFile|
      next if !zipFile.start_with? node_name
      File.delete "C:\\chef\\#{zipFile}" if zipFile.end_with? '.zip'
    end
  end
  only_if { File.directory?('C:\chef') }
end

file "C:\\chef\\#{file_name}.txt" do
  action :delete
end
