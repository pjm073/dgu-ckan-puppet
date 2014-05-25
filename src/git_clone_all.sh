#/usr/bin/env bash

# git clone steps
# ---------------

git clone	git@github.com:ckan/ckan
cd ckan
git checkout ckan-2.2
git checkout fa60dc947eb6db612218d8d89affec7d6df3b096
cd -

git clone	git@github.com:ckan/ckanext-harvest
cd ckanext-harvest
git checkout stable
cd -

git clone	git@github.com:ckan/ckanext-spatial
cd ckanext-spatial
git checkout stable
cd -

