require 'mina/rails'
require 'mina/git'
require 'mina/rvm'

# Basic settings:
set :application_name, 'app1'  # Your application name
set :domain, '147.79.75.87'     # Your server's IP address
set :user, fetch(:application_name)  # Username to SSH into the server
set :deploy_to, "/home/#{fetch(:user)}/app1"  # Path to deploy the application
set :repository, 'git@github.com:p-guelfi/app1.git'  # GitHub repository URL
set :branch, 'master'  # Branch to deploy
set :rvm_use_path, '/etc/profile.d/rvm.sh'  # Path to RVM

# Shared files and directories
set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')
set :shared_dirs, fetch(:shared_dirs, []).push('public/packs', 'node_modules')

# Remote environment task
task :remote_environment do
  ruby_version = File.read('.ruby-version').strip
  raise "Couldn't determine Ruby version: Do you have a file .ruby-version in your project root?" if ruby_version.empty?

  invoke :'rvm:use', ruby_version
end

# Setup task
task :setup do
  in_path(fetch(:shared_path)) do
    command %[mkdir -p config]

    # Create database.yml for Postgres if it doesn't exist
    path_database_yml = "config/database.yml"
    database_yml = %[production:
  database: #{fetch(:user)}
  adapter: postgresql
  pool: 5
  timeout: 5000]
    command %[test -e #{path_database_yml} || echo "#{database_yml}" > #{path_database_yml}]

    # Create secrets.yml with a static secret key for testing
    path_secrets_yml = "config/secrets.yml"
    secrets_yml = %[production:\n  secret_key_base: 'your_static_secret_here']
    command %[test -e #{path_secrets_yml} || echo "#{secrets_yml}" > #{path_secrets_yml}]

    # Remove others-permission for config directory
    command %[chmod -R o-rwx config]
  end
end

desc "Deploys the current version to the server."
task :deploy do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      # command "sudo systemctl restart #{fetch(:user)}"
    end
  end
end

# For help in making your deploy script, see the Mina documentation:
#  - https://github.com/mina-deploy/mina/tree/master/docs
