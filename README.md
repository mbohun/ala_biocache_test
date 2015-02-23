# ala_biocache_test
test scripts for Atlas of Living Australia biocache

###problem
(problem-s identified so far)
in production logs 

###solution
####1. test environment setup
* check and adjust if required `/etc/hosts` file on:
 - on any machine (for example your workstation) you are going to use to run the ansible installation scripts from, and/or later access the test env/vm with curl, webbrowser, etc.; the IP address, and hostname has to match the one in your ansible inventory for this installation
  ```
  130.56.244.8 biocache-test
  ```
 - once installed make sure your test env/vm `/etc/hosts` is setup correctly too
  ```
  127.0.0.1 biocache-test
  ```
* run the ansible-playbook to install the test env/vm; this is automated with ansible, using existing ala-demo playbook and inventiry as a starting point, although the following task-s/customization was done manually and could/should be automated with ansible:
 - vm setup/configuration for running tomcat, apache solr **THIS IS REQUIRED BECAUSE IF NOT SETUP CORRECTLY SOLR WILL KEEP CRASHING**
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
 - copy solr index from the production env onto your test env/vm into `/data/solr-indexes` and adjust `/data/solr/solr.xml` to point to the indexes/indices you copied into `/data/solr-indexes`:
  ```BASH
  # 1. stop tomcat and solr
  sudo service tomcat7 stop
   
  # 2. backup/rename the existing /data/solr directory
  
  # 3. copy the biocache indexes from prod
   
  # 4. TODO: confirm this step: copy? OR create? /data/solr instanceDir-s for each copied index/dataDir
  
  # 5. crate/adjust the /data/solr/solr.xml file to point to the, see bellow

  # 6. make sure all dir and files are owned by the tomcat user:
  sudo chown -R tomcat7:tomcat7 /data/solr
  sudo chown -R tomcat7:tomcat7 /data/solr-indexes
  
  # 7. restart tomcat and solr
  sudo service tomcat7 start
  ```

   `/data/solr/solr.xml`
   ```XML
   <?xml version="1.0" encoding="UTF-8" ?>
   <solr persistent="true">
      <cores adminPath="/admin/cores" defaultCoreName="biocache" host="${host:}" hostPort="${jetty.port:8983}" hostContext="${hostContext:solr}" zkClientTimeout="${zkClientTimeout:15000}">
         <core name="bie"      config="solrconfig.xml" instanceDir="/data/solr/bie/"      schema="schema.xml" dataDir="/data/solr-indexes/bie-03-12-2014"/>
         <core name="biocache" config="solrconfig.xml" instanceDir="/data/solr/biocache/" schema="schema.xml" dataDir="/data/solr-indexes/07-02-2015-07-54"/>
	  </cores>
   </solr>
   ```
  - test/verify your solr and biocache test env:
   ```BASH
   # verify solr search
   curl -s "http://biocache-test/solr/biocache/select?q=Pseudonaja&wt=json" | python -m json.tool | less
   # verify biocache-service service
   curl -s "http://biocache-test/biocache-service/occurrences/search?q=text:Pseudonaja" | python -m json.tool | less
   ```

* TODO:
  - **IMPORTANT:** both production and test env biocache-service (and most likely other services) ansible-playbook-s should make sure that `biocache-serice.log` and all other important (tomcat, solr, etc.) logs are properly preserved/archived (i found out accidentally on the 2015-02-20 when the `/var/log/tomcat7/biocache-service.log` was deleted, resp. replaced/reset and all the existing log messages starting from early January 2015 were lost)
  - check/verify the vm OS/kernel setup, for example if `CONFIG_PREEMT_NONE=y` is being used and not `CONFIG_PREEMPT_VOLUNTARY=y` or `CONFIG_PREEMPT=y`; see: [http://cateee.net/lkddb/web-lkddb/PREEMPT_NONE.html](http://cateee.net/lkddb/web-lkddb/PREEMPT_NONE.html) for more info on this.
   ```BASH
   hor22n@nci-biocache-test:~$ grep CONFIG_PREEMPT /boot/config-`uname -r`
   # CONFIG_PREEMPT_RCU is not set
   CONFIG_PREEMPT_NOTIFIERS=y
   # CONFIG_PREEMPT_NONE is not set
   CONFIG_PREEMPT_VOLUNTARY=y
   # CONFIG_PREEMPT is not set

   #This (CONFIG_PREEMPT_VOLUNTARY=y) is NOT what you want; you do want: CONFIG_PREEMPT_NONE=y because this is a server env.
   ```
  - 

####2. testing queries 
* [[org.ala.biocache.dao.SearchDAOImpl]](https://github.com/AtlasOfLivingAustralia/biocache-service/blob/master/src/main/java/au/org/ala/biocache/dao/SearchDAOImpl.java)
Error executing query with requestParams:
EXCEPTION: Server refused connection at: http://ala-rufus.it.csiro.au/solr
```
2015-02-20 11:23:39,892 [org.ala.biocache.dao.SearchDAOImpl] Error executing query with requestParams:
q=lsid:urn:lsid:biodiversity.org.au:afd.taxon:25c27ca8-906a-44d7-8450-0f08557cc58e
&fq=
&start=0
&pageSize=0
&sort=score
&dir=asc
&qc=
&facets=raw_taxon_name
&flimit=20
&formattedQuery=lft:[399022 TO 399023]
EXCEPTION: Server refused connection at: http://ala-rufus.it.csiro.au/solr
```
* [[org.ala.biocache.dao.SearchDAOImpl]](https://github.com/AtlasOfLivingAustralia/biocache-service/blob/master/src/main/java/au/org/ala/biocache/dao/SearchDAOImpl.java)
Problem communicating with SOLR server. Server refused connection at: http://ala-rufus.it.csiro.au/solr
org.apache.solr.client.solrj.SolrServerException: Server refused connection at: http://ala-rufus.it.csiro.au/solr
```
2015-02-20 11:23:39,894 [org.ala.biocache.dao.SearchDAOImpl] Problem communicating with SOLR server. Server refused connection at: http://ala-rufus.it.csiro.au/solr
org.apache.solr.client.solrj.SolrServerException: Server refused connection at: http://ala-rufus.it.csiro.au/solr
        at org.apache.solr.client.solrj.impl.HttpSolrServer.request(HttpSolrServer.java:428)
        at org.apache.solr.client.solrj.impl.HttpSolrServer.request(HttpSolrServer.java:180)
        at org.apache.solr.client.solrj.request.QueryRequest.process(QueryRequest.java:90)
        at org.apache.solr.client.solrj.SolrServer.query(SolrServer.java:310)
        at au.org.ala.biocache.dao.SearchDAOImpl.runSolrQuery(SearchDAOImpl.java:1509)
        at au.org.ala.biocache.dao.SearchDAOImpl.findByFulltext(SearchDAOImpl.java:2576)
        at sun.reflect.GeneratedMethodAccessor861.invoke(Unknown Source)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:309)
        at org.springframework.aop.framework.JdkDynamicAopProxy.invoke(JdkDynamicAopProxy.java:196)
        at com.sun.proxy.$Proxy25.findByFulltext(Unknown Source)
        at au.org.ala.biocache.web.WMSController.getBBox(WMSController.java:875)
        at au.org.ala.biocache.web.WMSController.jsonBoundingBox(WMSController.java:411)
        at sun.reflect.GeneratedMethodAccessor951.invoke(Unknown Source)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.springframework.web.bind.annotation.support.HandlerMethodInvoker.invokeHandlerMethod(HandlerMethodInvoker.java:176)
        at org.springframework.web.servlet.mvc.annotation.AnnotationMethodHandlerAdapter.invokeHandlerMethod(AnnotationMethodHandlerAdapter.java:436)
        at org.springframework.web.servlet.mvc.annotation.AnnotationMethodHandlerAdapter.handle(AnnotationMethodHandlerAdapter.java:424)
        at org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:790)
        at org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:719)
        at org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:669)
        at org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:574)
        at javax.servlet.http.HttpServlet.service(HttpServlet.java:621)
        at javax.servlet.http.HttpServlet.service(HttpServlet.java:722)
        at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:305)
        at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:210)
        at au.org.ala.web.filter.JsonpFilter.doFilter(JsonpFilter.java:52)
        at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:243)
        at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:210)
        at com.opensymphony.sitemesh.webapp.SiteMeshFilter.obtainContent(SiteMeshFilter.java:129)
        at com.opensymphony.sitemesh.webapp.SiteMeshFilter.doFilter(SiteMeshFilter.java:77)
        at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:243)
        at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:210)
        at org.springframework.web.filter.CharacterEncodingFilter.doFilterInternal(CharacterEncodingFilter.java:88)
        at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:76)
        at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:243)
        at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:210)
        at org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:224)
        at org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:169)
        at org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:472)
        at org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:168)
        at com.googlecode.psiprobe.Tomcat70AgentValve.invoke(Tomcat70AgentValve.java:38)
        at org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:98)
        at org.apache.catalina.valves.AccessLogValve.invoke(AccessLogValve.java:927)
        at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:118)
        at org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:407)
        at org.apache.coyote.http11.AbstractHttp11Processor.process(AbstractHttp11Processor.java:987)
        at org.apache.coyote.AbstractProtocol$AbstractConnectionHandler.process(AbstractProtocol.java:579)
        at org.apache.tomcat.util.net.JIoEndpoint$SocketProcessor.run(JIoEndpoint.java:309)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
        at java.lang.Thread.run(Thread.java:744)
Caused by: org.apache.http.conn.HttpHostConnectException: Connection to http://ala-rufus.it.csiro.au refused
        at org.apache.http.impl.conn.DefaultClientConnectionOperator.openConnection(DefaultClientConnectionOperator.java:190)
        at org.apache.http.impl.conn.ManagedClientConnectionImpl.open(ManagedClientConnectionImpl.java:294)
        at org.apache.http.impl.client.DefaultRequestDirector.tryConnect(DefaultRequestDirector.java:645)
        at org.apache.http.impl.client.DefaultRequestDirector.execute(DefaultRequestDirector.java:480)
        at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:906)
        at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:805)
        at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:784)
        at org.apache.solr.client.solrj.impl.HttpSolrServer.request(HttpSolrServer.java:365)
        ... 53 more
Caused by: java.net.ConnectException: Connection refused
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:339)
        at java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:200)
        at java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:182)
        at java.net.SocksSocketImpl.connect(SocksSocketImpl.java:392)
        at java.net.Socket.connect(Socket.java:579)
        at org.apache.http.conn.scheme.PlainSocketFactory.connectSocket(PlainSocketFactory.java:127)
        at org.apache.http.impl.conn.DefaultClientConnectionOperator.openConnection(DefaultClientConnectionOperator.java:180)
        ... 60 more
```


####3. prod log analysis
* write a script/scripts that extract diff types of errors/exceptions from biocache-service.log and visualise/plot the frequency of diff types of errors over period of time
 - for example to extract the timestamps of the "Proxy Error" messages:
  ```BASH
  #!/bin/bash
  
  # for each log file if we have many, collect $ERROR_PATTER and accumulate the matches in some tmp file
  grep -i 'proxy error' ./biocache-service.log | grep '^201[5-9]' | sed -e 's/ \[org.*$//g' > proxy_error-all.dat
  
  # for each day extract the number of errors
  for day in `cat proxy_error-all.dat | sed -e 's/ .*$//g' | sort | uniq`
  do
      counter=`grep ${day} proxy_error-all.dat | wc -l`
      echo "${day} ${counter}"
  done
  ```

  ```BASH
  ./extract-errors-per-day.sh > errors-per-day-example.dat
  gnuplot errors-per-day-example.gnuplot
  ```
  example output (errors-per-day-histogram.png):
  ![Alt text](https://raw.githubusercontent.com/mbohun/ala_biocache_test/master/errors-per-day-histogram.png "example ouptut")

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
