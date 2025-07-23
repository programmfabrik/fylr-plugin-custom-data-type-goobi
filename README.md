> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# fylr-plugin-custom-data-type-goobi
Custom Data Type "goobi" for easydb

This is a plugin for [fylr](https://docs.fylr.io/) with Custom Data Type `CustomDataTypeGoobi` for references to entities to [Goobi workflow](<https://www.intranda.com/digiverso/goobi/>).

The Plugins uses <http://my-goobi.tld/api/processes/search> for the autocomplete-suggestions and additional informations about the goobi-processes.

## installation

The latest version of this plugin can be found [here](https://github.com/programmfabrik/fylr-plugin-custom-data-type-goobi/releases/latest/download/customDataTypeGoobi.zip).

The ZIP can be downloaded and installed using the plugin manager, or used directly (recommended).

Github has an overview page to get a list of [all releases](https://github.com/programmfabrik/fylr-plugin-custom-data-type-goobi/releases/).

## requirements
This plugin requires https://github.com/programmfabrik/fylr-plugin-commons-library. In order to use this Plugin, you need to add the [commons-library-plugin](https://github.com/programmfabrik/fylr-plugin-commons-library) to your pluginmanager.

## configuration

As defined in `manifest.yml` this datatype can be configured:

### Schema options

* goobi-field used for "Name"
* goobi-field used for "URI"

### Mask-settings
* goobi-API-url
* goobi-endpoint-token
* Searchable goobi-projects (commaseparated)
* Searchable metadatafields (commaseparated)

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/fylr-plugin-custom-data-type-goobi>.