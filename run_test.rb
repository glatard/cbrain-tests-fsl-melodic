
#!/usr/bin/env ruby

require 'cbrain_ruby_api'
require 'json'

class CbrainRubyAPI
  @overwrite_none=false
  @overwrite_all=false

  attr_accessor :overwrite_none
  attr_accessor :overwrite_all
  
  # This method will:
  #  * Check if file file_name is present locally.
  #  * Delete the file on CBRAIN if it has to be overwritten.
  #  * Upload the file to CBRAIN.
  #  * Wait for the file synchronization status to be "InSync".
  # Parameters:
  #  * data_dir: a directory in the local host.
  #  * file_name: a file name in this directory (no sub-directories are allowd).
  #  * content_type: the HTTP content type,  e.g., "application/octet-stream" or "text/plain".
  #  * cbrain_type: the file type in CBRAIN, e.g. "SingleFile".
  #  * cbrain_data_provider_id: the id of a CBRAIN data provider where the file will be stored.
  # Returns the id of the created or existing file.
  
  def check_existence_upload_file_and_wait data_dir,file_name,content_type,cbrain_type,cbrain_data_provider_id

    absolute_file_name = File.join(data_dir,file_name)
    raise "!! File does not exist: #{absolute_file_name}" unless File.exist?(absolute_file_name)
    userfiles = index_userfiles({:data_provider_id => cbrain_data_provider_id, :name => file_name})
    # Redo the call a second time, just in case (see API bug #5)
    userfiles = index_userfiles({:data_provider_id => cbrain_data_provider_id, :name=>file_name})
    if userfiles.size > 1
      puts "!! Found the following file ids with name #{file_name} on data provider #{cbrain_data_provider_id}:"
      userfiles.each do |f|
        puts "!! #{f[:id]}"
      end
      raise "!! Found more than 1 file with name #{file_name} on data provider #{cbrain_data_provider_id}" 
    end
    
    if !userfiles.empty? # file exists
      return userfiles[0][:id] if @overwrite_none # file exists and no file must be overwritten: do nothing. 
      overwrite = @overwrite_all ? true : ask_overwrite(userfiles[0][:name],userfiles[0][:id])
      return userfiles[0][:id] if !overwrite # file exists and file mustn't be overwritten: do nothing.
      puts "-- Deleting file #{userfiles[0][:name]} with id #{userfiles[0][:id]}..." # delete file and fall into the "file doesn't exist case"
      delete_userfiles(userfiles[0][:id])
    end

    # File doesn't exist: upload it
    puts "++ Uploading file #{file_name} (#{File.size(absolute_file_name)} bytes)..."
    params   =   { :data_provider_id          => cbrain_data_provider_id,
                   :archive                   => "save",
                   :file_type                 => cbrain_type,
                   "userfile[group_id]"       => 1, # everyone
                   "userfile[group_writable]" => false,
                 }
    
    response = create_userfile(
      absolute_file_name,
      content_type,
      params)
    puts "#{response}" if !response.nil? && !response==""

    # Check that the file is in CBRAIN and wait for the synchronization status to be "InSync"
    userfiles = index_userfiles({:data_provider_id => cbrain_data_provider_id, :name=>file_name})
    # Redo the call a second time, just in case (see API bug #5)
    userfiles = index_userfiles({:data_provider_id => cbrain_data_provider_id, :name=>file_name})
    raise "!! Cannot find file with name #{file_name} on data provider #{cbrain_data_provider_id}" if userfiles.empty?
    raise "!! Found more than 1 file with name #{file_name} on data provider #{cbrain_data_provider_id}" if userfiles.size > 1
    print ".. Waiting for file #{file_name} to be synchronized"
    begin
      sleep 1
      userfile_info = show_userfile(userfiles[0][:id])
      if userfile_info.blank? or userfile_info[:remote_sync_status].blank? or userfile_info[:remote_sync_status].empty?
        print "x"
        next
      end
      status = userfile_info[:remote_sync_status][0][:status]
      print "."
    end while status != "InSync"
    puts ""
    
    return userfiles[0][:id]
  end
  
  private
  def ask_overwrite file_name, file_id 
    puts "?? Overwrite existing file #{file_name} with id #{file_id}? yes (y), no (n), all (a), none (o)"
    delete = $stdin.gets.downcase.strip
    if delete == "y" 
      return true
    end
    if delete == "a"
      @overwrite_all = true
      return true
    end
    if delete == "n"
      return false
    end
    if delete == "o"
      @overwrite_none = true
      return false
    end
    puts "!! Invalid answer!"
    ask_overwrite(file_name,file_id)
  end
end

class String
  def image_file_type
    return "NiftiFile" if self.end_with?(".nii",".nii.gz")
    return "MincFile"  if self.end_with?(".mnc")
    raise "!! Unknown file extension: #{functional_file_name}"
  end
end

# Arguments parsing
if ARGV.size < 2 || ARGV.size > 3 || ARGV[0]=="-h" || ARGV[0]=="--help"
  puts "Usage: run_test.rb <test_file> <data_dir> [options]"
  puts "           test_file: a JSON file containing the test specifications."
  puts "           data_dir:  a directory where all the files referenced in <test_file> 
                              are located. Sub-directories MUST NOT be used
                              (all the files have to be in the same base directory)."
  puts "        options:"
  puts "           --overwrite-all: overwrite all the files."
  puts "           --overwrite-none: do not overwrite any file."
  exit 1
end
test_file = ARGV[0]
data_dir  = ARGV[1]
overwrite_mode = ARGV[2]
if !overwrite_mode.blank? && overwrite_mode!="--overwrite-all" && overwrite_mode!="--overwrite-none"
  raise "!! Unknown option: #{overwrite_mode}"
end

test = JSON.parse File.read test_file
puts "ii Class: \"#{test["test-class"]}\", Test: \"#{test["name"]}\", File: \"#{test_file}\""


# CBRAIN configuration
configuration_file=File.join(ENV['HOME'],".cbrain_api")

configuration = Hash.new
configuration = JSON.parse File.read configuration_file if File.exist? configuration_file
if configuration['cbrain-endpoint'].blank?
  puts "?? CBRAIN endpoint (e.g.: http://localhost:3000)"
  configuration['cbrain-endpoint'] = $stdin.gets.chomp
end
if configuration['cbrain-login'].blank?
  puts "?? CBRAIN login: (e.g.: foo)"
  configuration['cbrain-login'] = $stdin.gets.chomp
end
if configuration['cbrain-password'].blank?
  puts "?? CBRAIN password:"
  configuration['cbrain-password'] = $stdin.gets.chomp
end
if configuration['cbrain-data-provider-id'].blank?
  puts "?? CBRAIN data provider id:"
  configuration['cbrain-data-provider-id'] = $stdin.gets.chomp.to_i
end
if configuration['fsl-melodic-tool-config-id'].blank?
  puts "?? FSL Melodic tool config id:"
  configuration['fsl-melodic-tool-config-id'] = $stdin.gets.chomp.to_i
end
File.open(configuration_file,"w") do |f|
  f.write(configuration.to_json)
end
cbrain_endpoint = configuration['cbrain-endpoint']
cbrain_login = configuration['cbrain-login']
cbrain_password = configuration['cbrain-password']
cbrain_data_provider_id = configuration['cbrain-data-provider-id']
fsl_melodic_tool_config_id = configuration['fsl-melodic-tool-config-id']

# Login
agent = CbrainRubyAPI.new(cbrain_endpoint)
agent.login(cbrain_login,cbrain_password)

# Overwrite mode
if overwrite_mode == "--overwrite-all"
  agent.overwrite_all = true
else if overwrite_mode == "--overwrite-none"
  agent.overwrite_none = true
end
end

# Task parameters
task_params = Hash.new
test["parameters"].each_with_object({}){|(k,v), h| task_params[k.to_sym] = v}
  
csv_file_name = test["input-file-names"]["csv-file-name"]
design_file_name = test["input-file-names"]["design-file-name"]
template_file_name = test["input-file-names"]["template-file-name"]
  
# Parse CSV file
File.open(File.join(data_dir,csv_file_name)).each do |line|

  # Get names and types of functional and anatomical files
  values = line.split(",")
  raise "CSV file is not well formatted: #{line}" if values.size != 2
  functional_file_name = values[0].strip
  anatomical_file_name = values[1].strip

  # Upload files
  agent.check_existence_upload_file_and_wait(
    data_dir,
    functional_file_name,
    "application/octet-stream",
    functional_file_name.image_file_type,
    cbrain_data_provider_id)
  agent.check_existence_upload_file_and_wait(
    data_dir,
    anatomical_file_name,
    "application/octet-stream",
    anatomical_file_name.image_file_type,
    cbrain_data_provider_id)
end
  
# Upload CSV, design, and template files
input_files = Array.new
input_files << agent.check_existence_upload_file_and_wait(
  data_dir,
  csv_file_name,
  "text/plain",
  "CSVFile",
  cbrain_data_provider_id)
input_files << agent.check_existence_upload_file_and_wait(
  data_dir,
  design_file_name,
  "text/plain",
  "FSLDesignFile",
  cbrain_data_provider_id)

if !template_file_name.blank?
  regstandard_file_id = agent.check_existence_upload_file_and_wait(
    data_dir,
    template_file_name, 
    "application/octet-stream",
    template_file_name.image_file_type,
    cbrain_data_provider_id)
  task_params[:regstandard_file_id] = regstandard_file_id
end

# Task submission
task_description = "Test class: \"#{test["test-class"]}\"\n Test: \"#{test["name"]}\"\nExpected status: \"#{test["expected-task-status"]}\""
task_ids = agent.create_task( input_files,
                              fsl_melodic_tool_config_id,
                                {'description' => "#{task_description}"},
                                task_params)

if task_ids.nil?
  puts"!! Task submission failed. Maybe the file content is not correct. Try to submit the task manually in CBRAIN to check your data."
  puts "#{agent.error_message()}"
  exit 1
end

task_ids.each do |id|
    puts "ii Submitted task #{id}"
end
