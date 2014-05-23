# Data.gov.uk To Go

This repo provides scripts to install a copy of data.gov.uk's website to your own server. It has been rebrand and modified to fit the specific needs of Stumptown Labs

## About

The UK Government has contributed Data.gov.uk To Go to Github to kick-start the use and development of common open data portal software, beyond the basic CKAN. UK wants to develop it in partnership with other providers of Open Data portals, through the usual Open Source / Github model of forking, pull requests, issues etc. that everyone is encouraged to contribute to.

## Overview

Here is an overview of the install process:

* Machine preparation - Vagrant VM or a fresh Ubuntu 12.04 machine
* CKAN source - download from Github
* Puppet provision of the main software packages (Apache, Postgres, SOLR etc) and set-up linux users
* CKAN database setup
* Drupal install
* Additional configuration

## Suggested system requirements

* 24GB RAM
* 8 cores
* 200GB disc

## 1. Machine preparation

### Download this build repo from Github

Clone this repo (its path will now be referred to as $THIS_REPO) and switch to the 'togo' branch:

    git clone https://github.com/pjm073/dgu-ckan-puppet.git -b togo
    cd dgu-ckan-puppet
    git checkout togo


### Option 1: Fresh machine preparation

Instead of using a virtual-machine it is perfectly fine alternative to use a non-virtual machine, freshly installed with Ubuntu 12.04. The Puppet scripts assume the name of the machine is 'ckan', so you need to ssh to it and rename it:

    sudo hostname ckan
    sudo vim /etc/hosts
    # ^ add "127.0.0.1  ckan" to hosts...

Puppet also assumes your home user is 'ubuntu', so ensure that is created and can login as sudo.

    sudo adduser ubuntu
    sudo visudo
    su ubuntu

You need to install some dependencies:

    sudo apt-get install rubygems git
    sudo gem install librarian-puppet 

And move the dgu-ckan-puppet repo to the place where it would end up if using Vagrant:

    sudo mv ~/dgu-ckan-puppet /vagrant

All further steps are to be carried out from the ssh session under the user 'ubuntu' on this target machine.

## 2. CKAN source - download from Github

Use the script to clone all the CKAN source repos.

If using a Vagrant VM, do this step on the host machine, not the VM.

You may need to install git first (and verify SSH keys are present on GitHub). 

    cd $THIS_REPO/src
    ./git_clone_all.sh

## 3. Puppet provision

Puppet is used to install and configure the main software packages (Apache, Postgres, SOLR etc) and setup linux users.

To provision an existing machine, install the puppet modules:

    sudo /vagrant/puppet/install_puppet_dependancies.sh

and then execute the site manifest now at /etc/puppet/:

    sudo puppet apply /vagrant/puppet/manifests/site.pp

You can ignore this warning:

    warning: Could not retrieve fact fqdn

NB There is an issue with permissions which should be resolved in a few days.

## 4. Run Grunt on the assets

Data.gov.uk uses Grunt to do pre-processing of Javascript and CSS scripts as well as images and it writes timestamps to help with cache versioning. Install a recent version of NodeJS:

    sudo apt-get install python-software-properties python g++ make
    sudo add-apt-repository ppa:chris-lea/node.js
    sudo apt-get update
    sudo apt-get install nodejs

Now install the Grunt CLI tools globally:

    sudo npm install -g grunt-cli

For each of the two repos with assets, install the required Node modules and run the Grunt scripts:

    cd /vagrant/src/ckanext-dgu
    sudo npm install
    grunt
    cd /vagrant/shared_dguk_assets
    sudo npm install
    grunt

When changes are made to the assets in these repos, you need to rerun Grunt.

There is more about Grunt use here: https://github.com/datagovuk/shared_dguk_assets/blob/master/README.md

## 5. CKAN Database setup

**IMPORTANT** You must activate the CKAN virtual environment when working on the VM. Eg.:

    source ~/ckan/bin/activate

And make sure you run paster commands from the /vagrant/src/ckan directory.

#### Option 1: Use test data

    createdb -O dgu ckan --template template_postgis
    paster --plugin=ckanext-ga-report initdb --config=ckan.ini
    paster --plugin=ckanext-dgu create-test-data --config=ckan.ini
    paster search-index rebuild --config=ckan.ini

#### Option 2: Download an existing database

At data.gov.uk we download a database (using pg_dump and gzip) from another server like:

    mkdir -p /vagrant/db_backup
    rsync --progress co@co-prod1.dh.bytemark.co.uk:/var/backups/ckan/dgu.2013-07-09.pg_dump.gz /vagrant/db_backup/

Then load the dump in:

    export CKAN_DUMP_FILE=`ls /vagrant/db_backup/ -t |head -n 1` && echo $CKAN_DUMP_FILE
    sudo apachectl stop
    dropdb ckan
    createdb -O dgu ckan --template template_postgis
    pv /vagrant/db_backup/$CKAN_DUMP_FILE | funzip \
      | PGPASSWORD=pass psql -h localhost -U dgu -d ckan
    sudo apachectl start
    paster db upgrade --config=ckan.ini
    paster search-index rebuild --config=ckan.ini

### Give yourself a CKAN user for debug (optional)

For test purposes you can add a CKAN admin user. Remember to reset the password before making the site live.

    paster user add admin email=admin@ckan password=pass --config=ckan.ini
    paster sysadmin add admin --config=ckan.ini

## CKAN Paster commands

When running CKAN paster commands, you should activate the virtualenv and run the paster commands from the ckan source directory:

    source /home/vagrant/bin/activate
    cd /vagrant/src/ckan

Examples::

    paster create-test-data --config=ckan.ini
    paster search-index rebuild --config=ckan.ini
    paster --plugin=ckanext-dgu celeryd run concurrency=1 --queue=priority --config=ckan.ini

Find full details of the CKAN paster commands is here: http://docs.ckan.org/en/ckan-2.0.2/paster.html

## 6. Drupal install

For Drupal you will need to complete the configuration of the LAMP stack and get a working drush installation.  Please see https://drupal.org/requirements for detailed requirements. You can get drush and it's installation instructions from
here: https://github.com/drush-ops/drush

Get the DGU Drupal Distribution using:

    git clone https://github.com/datagovuk/dgu_d7.git

You can install drupal with the following drush command:

````bash
$ drush make distro.make /var/www/
$ drush --yes --verbose site-install dgu --db-url=mysql://user:pass@localhost/db_name --account-name=admin --account-pass=password  --site-name='something creative'
```

This will install drupal, download all the required modules and configure the system.  After this step completes
successfully, you should enable some modules:

````bash
$ drush --yes en dgu_site_feature  
$ drush --yes en composer_manager  
$ drush --yes en dgu_app dgu_blog dgu_consultation dgu_data_set dgu_data_set_request dgu_footer dgu_forum dgu_glossary dgu_idea dgu_library dgu_linked_data dgu_location dgu_organogram dgu_promo_items dgu_reply dgu_shared_fields dgu_user dgu_taxonomy ckan dgu_search dgu_services dgu_home_page
$ drush --yes en ckan
````

You will need to configure drupal with the url of your CKAN instance.  We use the following drush commands:
````bash
$ drush vset ckan_url 'http://data.gov.uk/api/';
$ drush vset ckan_apikey 'xxxxxxxxxxxxxxxxxxxxx';
````
You may also check and modify these settings in the admin menu: configuration->system->ckan.

We have also written some migration classes for migrating our existing Drupal 6 web site to version 7.  The order
that we run these tasks is important.  After installation, we run the following drush commands to migrate our web site:

````bash
$ drush migrate-import --group=User --debug  
$ drush migrate-import --group=Taxonomy  
$ drush migrate-import --group=Files --debug  
$ drush migrate-import --group=Datasets --debug  
$ drush migrate-import --group=Nodes --debug  
$ drush migrate-import --group=Paths --debug  
$ drush migrate-import --group=Comments --debug  
````

The migration depends on finding drupal variables to tell it where to look to find files and the data,
so, before you can run the migration, you will to add something like the following to your settings.php file:

````php
$conf['drupal6files'] = '/var/www/old_files';
$databases['d6source']['default'] = array(
    'driver' => 'mysql',
    'database' => 'drupal_d6',
    'username' => 'web',
    'password' => 'supersecret',
    'host' => 'localhost',
    'prefix' => '',
);
````

Drupal uses a second SOLR core.

## 7. Additional configuration

In this example, both Drupal and CKAN are served from a single vhost of Apache. An example is provided: resources/apache.vhost

For a live deployment it would make sense to adjust the database passwords.



