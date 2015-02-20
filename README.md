# ala_biocache_test
test scripts for Atlas of Living Australia biocache

###problem
(problem-s identified so far)
in production logs 

###solution
**1.** test environment setup
* automated with ansible, using existing ala-demo as a starting point
  - add ansible task to check swap settings, and if not present setup/add swap file
  - add ansible task to create `$CATALINA_BASE/bin/setenv.sh` script to configure `JAVA_OPTS` for running apache solr; **THIS IS REQUIRED BECAUSE IF NOT SETUP CORRECTLY SOLR WILL KEEP CRASHING**
* vm setup/configuration for tomcat, apache-solr and biocache-services
```
SWAP = 2 x RAM
 Xms = RAM / 2
 Xmx = RAM / 2
--------------
# for example if your vm has 32gb RAM, configure it as foillows:
SWAP = 64gb
 Xms = 16gb
 Xmx = 16gb

# your JAVA_OPTS for tomcat startup will be set to:
JAVA_OPTS="-Xms16g -Xmx16g -XX:MaxPermSize=256m -Xss256k"
```
create `$CATALINA_BASE/bin/setenv.sh` (for example: `/usr/share/tomcat7/bin/setenv.sh`) file:
```BASH
#!/bin/sh

JAVA_OPTS="-Xms16g -Xmx16g -XX:MaxPermSize=256m -Xss256k"

```
and make it executable:
```BASH
sudo chmod +x /usr/share/tomcat7/bin/setenv.sh
```
* travis-ci build file created to deploy the biocache test env ansible-playbook into the vm

**2.** 
* [org.ala.biocache.dao.SearchDAOImpl](https://github.com/AtlasOfLivingAustralia/biocache-service/blob/master/src/main/java/au/org/ala/biocache/dao/SearchDAOImpl.java)
* 


####NOTES:
**TODO:** move this, or at least structure this into sections/parts as we go

```BASH
bash-3.2$ curl -s "http://biocache-test/biocache-service/occurrences/search?q=text:scutatus" \
               | ./biocache-search-test-utils.py -j '$.facetResults[*].fieldName' \
			   | sort
			   
alau_user_id
assertion_user_id
assertions
basis_of_record
cl1918
cl617
cl620
cl959
cl966
class
collection_uid
collector
common_name
country
data_provider_uid
data_resource_uid
duplicate_status
family
genus
geospatial_kosher
ibra
imcra
institution_uid
kingdom
month
multimedia
occurrence_status_s
occurrence_year
order
outlier_layer
outlier_layer_count
phylum
provenance
rank
raw_taxon_name
species
species_group
species_habitats
state
subspecies_name
taxon_name
taxonomic_issue
type_status
uncertainty
year
```

```BASH
bash-3.2$ curl -s "http://biocache-test/biocache-service/occurrences/search?q=text:scutatus" \
               | ./biocache-search-test-utils.py -j '$.facetResults[0].fieldResult[*].label'

AVES
Argyrodes fissifrons
Aspidiobates scutatus
Centriscus scutatus
Gennadas scutatus
ISCHYROCERIDAE
Laticauda
Notechis
Notechis scutatus
Notechis scutatus ater
Notechis scutatus humphreysi
Notechis scutatus niger
Notechis scutatus occidentalis
Notechis scutatus scutatus
Notechis scutatus serventyi
Notoplites
Plantae
Pseudoscopelus
Rumex
Simognathus scutatus
Sphenomorphus
Tasmanobates scutatus
Terobiella scutata
```
