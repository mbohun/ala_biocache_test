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

####2. prod log analysis
* Intro
 - Limitations & Constraints
   Main limitation at the moment is the lack of information/details/sample/example queries that "are running slow" to compare them with "normal" queries to disect the problem deper.
* SPAM queries these usually (most of the time) match the regexp `'^201[4-9]-[0-1][0-9]-[0-3][0-9].*\[org.ala.biocache.dao.SearchDAOImpl\] Error executing query with requestParams: q=text:.*http[s]*://'` (intentionally kept simple for clarity; the log message (like all) starts with a timestamp (partially restriceted here), followed by a constant string composed of the class name, the error itself, followed by the q=text: containing/followed by a HTTP/HTTPS link / URL to some online shop, BUT excluding matches where the erroro log line contains a valid URL). *example:*
  ```BASH
  sudo grep \
  '^201[4-9]-[0-1][0-9]-[0-3][0-9].*\[org.ala.biocache.dao.SearchDAOImpl\] Error executing query with requestParams: q=text:.*http[s]*://' \
  /var/log/tomcat7/biocache-service.log \
  | grep -v 'http[s]*\://ala\-rufus'
  ```
  This should be flitered off ASAP to avoid any further processing as much as possible. This should be rather easy to benchmark, as in setup a test case where the same N legimitate/normal queries will be:
  - executed WITHOUT any interference/competition from SPAM queries
  - executed WITH interference/competition from SPAM queries
* Errors summary
  - extract all available/captured error types
   - count/plot each error type total (for a given time/date range) 
   - count/plot each error type total per day (on a timeline)

  ```BASH
  sudo grep '^201[4-9]-[0-1][0-9]-[0-3][0-9].*\[[a-zA-Z0-9.]*\]' /var/log/tomcat7/biocache-service.log | sed -e 's/].*$/]/g' | sed -e 's/^.*\[/[/' | sort | uniq
  [org.ala.biocache.dao.SearchDAOImpl]
  [org.ala.biocache.service.AuthService]
  [org.ala.biocache.service.DownloadService]
  [org.ala.biocache.util.CollectionsCache]
  [org.ala.biocache.web.MapController]
  [org.ala.biocache.web.WMSController]
  ```
  ```BASH
  bash-3.2$ ./create-error-summary.sh ./2015-02-24-biocache-service.log
  [org.ala.biocache.dao.SearchDAOImpl]     582
  [org.ala.biocache.service.AuthService]      68
  [org.ala.biocache.service.DownloadService]       9
  [org.ala.biocache.util.CollectionsCache]       6
  [org.ala.biocache.web.MapController]       3
  [org.ala.biocache.web.WMSController]      36
  ```

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
* [[org.ala.biocache.dao.SearchDAOImpl]](https://github.com/AtlasOfLivingAustralia/biocache-service/blob/master/src/main/java/au/org/ala/biocache/dao/SearchDAOImpl.java)
EXCEPTION: Server at http://ala-rufus.it.csiro.au/solr returned non ok status:502, message:Proxy Error
```
2015-02-20 12:56:43,136 [org.ala.biocache.dao.SearchDAOImpl] Error executing query with requestParams: q=lsid:urn:lsid:biodiversity.org.au:afd.taxon:34b8f2b3-0828-4bd5-a307-c4598fa453b5 AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true&fq=&start=0&pageSize=0&sort=score&dir=a
sc&qc=&formattedQuery=lft:[405735 TO 405736] AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true EXCEPTION: Server at http://ala-rufus.it.csiro.au/solr returned non ok status:502, message:Proxy Error

2015-02-20 12:57:24,726 [org.ala.biocache.dao.SearchDAOImpl] Error executing query with requestParams: q=lsid:urn:lsid:biodiversity.org.au:afd.taxon:59c557c7-8751-473a-a758-2981c844b320 AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true&fq=&start=0&pageSize=0&sort=score&dir=a
sc&qc=&formattedQuery=lft:[409368 TO 409369] AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true EXCEPTION: Server at http://ala-rufus.it.csiro.au/solr returned non ok status:502, message:Proxy Error

2015-02-20 12:57:24,726 [org.ala.biocache.dao.SearchDAOImpl] Error executing query with requestParams: q=type_status:[* TO *]&fq=-type_status:notatype&fq=name_match_metric:"exactMatch"&fq=sensitive:"generalised"&start=0&pageSize=20&sort=first_loaded_date&dir=desc&qc=&facets=taxon_name&facets=com
mon_name&facets=subspecies_name&facets=species&facets=family&facets=species_group&facets=species_habitats&facets=uncertainty&facets=sensitive&facets=state_conservation&facets=location_id&facets=cl966&facets=cl959&facets=state&facets=country&facets=ibra&facets=imcra&facets=cl1918&facets=cl617&fac
ets=cl620&facets=geospatial_kosher&facets=month&facets=decade&facets=event_id&facets=basis_of_record&facets=type_status&facets=multimedia&facets=collector&facets=occurrence_status_s&facets=alau_user_id&facets=data_provider_uid&facets=data_resource_uid&facets=assertions&facets=assertion_user_id&f
acets=outlier_layer&facets=outlier_layer_count&facets=taxonomic_issue&facets=duplicate_status&facets=establishment_means&facets=user_assertions&facets=name_match_metric&facets=duplicate_type&facets=raw_datum&facets=raw_sex&facets=life_stage&facets=elevation_d_rng&facets=identified_by&facets=spec
ies_subgroup&flimit=10&formattedQuery=type_status:[* TO *] EXCEPTION: Server at http://ala-rufus.it.csiro.au/solr returned non ok status:502, message:Proxy Error

2015-02-20 12:57:24,729 [org.ala.biocache.dao.SearchDAOImpl] Error executing query with requestParams: q=lsid:urn:lsid:catalogueoflife.org:taxon:3386c832-4661-11e1-9b0d-e752e483e0da:col20120124 AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true&fq=&start=0&pageSize=0&sort=sco
re&dir=asc&qc=&formattedQuery=lft:[221826 TO 222379] AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true EXCEPTION: Server at http://ala-rufus.it.csiro.au/solr returned non ok status:502, message:Proxy Error

2015-02-20 13:02:35,116 [org.ala.biocache.dao.SearchDAOImpl] Error executing query with requestParams: q=collection_uid:co55&fq=assertions:"geodeticDatumAssumedWgs84"&fq=subspecies_name:"Abelmoschus manihot subsp. tetraphyllus"&fq=cl1918:"Primarily Vegetated Natural & Semi-Natural Terrestrial Ve
getation Woody Trees Closed"&start=0&pageSize=20&sort=first_loaded_date&dir=desc&qc=&facets=taxon_name&facets=common_name&facets=subspecies_name&facets=species&facets=family&facets=species_group&facets=species_habitats&facets=uncertainty&facets=sensitive&facets=state_conservation&facets=location
_id&facets=cl966&facets=cl959&facets=state&facets=country&facets=ibra&facets=imcra&facets=cl1918&facets=cl617&facets=cl620&facets=geospatial_kosher&facets=month&facets=decade&facets=event_id&facets=basis_of_record&facets=type_status&facets=multimedia&facets=collector&facets=occurrence_status_s&f
acets=alau_user_id&facets=data_provider_uid&facets=data_resource_uid&facets=assertions&facets=assertion_user_id&facets=outlier_layer&facets=outlier_layer_count&facets=taxonomic_issue&facets=duplicate_status&facets=establishment_means&facets=user_assertions&facets=name_match_metric&facets=duplica
te_type&facets=raw_datum&facets=raw_sex&facets=life_stage&facets=elevation_d_rng&facets=identified_by&facets=species_subgroup&flimit=10&formattedQuery=collection_uid:co55 EXCEPTION: Server at http://ala-rufus.it.csiro.au/solr returned non ok status:502, message:Proxy Error

2015-02-20 13:02:35,117 [org.ala.biocache.dao.SearchDAOImpl] Error executing query with requestParams: q=lsid:urn:lsid:biodiversity.org.au:afd.taxon:5dab26f3-b0a7-431a-a31d-b897aeaf0c30 AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true&fq=&start=0&pageSize=0&sort=score&dir=a
sc&qc=&formattedQuery=lft:[402676 TO 402725] AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true EXCEPTION: Server at http://ala-rufus.it.csiro.au/solr returned non ok status:502, message:Proxy Error

2015-02-20 13:02:35,117 [org.ala.biocache.dao.SearchDAOImpl] Error executing query with requestParams: q=lsid:urn:lsid:biodiversity.org.au:apni.taxon:344931 AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true&fq=&start=0&pageSize=0&sort=score&dir=asc&qc=&formattedQuery=lft:[25
9525 TO 259526] AND (country:"Australia" OR state:[* TO *]) AND geospatial_kosher:true EXCEPTION: Server at http://ala-rufus.it.csiro.au/solr returned non ok status:502, message:Proxy Error
```
* [[org.ala.biocache.service.DownloadService]](https://github.com/AtlasOfLivingAustralia/biocache-service/blob/master/src/main/java/au/org/ala/biocache/service/DownloadService.java)
org.apache.solr.client.solrj.SolrServerException:
IOException occured when talking to server at: http://ala-rufus.it.csiro.au/solr
```
2015-02-20 13:09:01,967 [org.ala.biocache.service.DownloadService] org.apache.solr.client.solrj.SolrServerException: IOException occured when talking to server at: http://ala-rufus.it.csiro.au/solr
java.util.concurrent.ExecutionException: org.apache.solr.client.solrj.SolrServerException: IOException occured when talking to server at: http://ala-rufus.it.csiro.au/solr
        at java.util.concurrent.FutureTask.report(FutureTask.java:122)
        at java.util.concurrent.FutureTask.get(FutureTask.java:188)
        at au.org.ala.biocache.dao.SearchDAOImpl.writeResultsFromIndexToStream(SearchDAOImpl.java:711)
        at sun.reflect.GeneratedMethodAccessor1010.invoke(Unknown Source)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:309)
        at org.springframework.aop.framework.JdkDynamicAopProxy.invoke(JdkDynamicAopProxy.java:196)
        at com.sun.proxy.$Proxy25.writeResultsFromIndexToStream(Unknown Source)
        at au.org.ala.biocache.service.DownloadService.writeQueryToStream(DownloadService.java:165)
        at au.org.ala.biocache.service.DownloadService.writeQueryToStream(DownloadService.java:134)
        at au.org.ala.biocache.service.DownloadService.writeQueryToStream(DownloadService.java:226)
        at au.org.ala.biocache.web.OccurrenceController.occurrenceIndexDownload(OccurrenceController.java:800)
        at sun.reflect.GeneratedMethodAccessor1008.invoke(Unknown Source)
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
Caused by: org.apache.solr.client.solrj.SolrServerException: IOException occured when talking to server at: http://ala-rufus.it.csiro.au/solr
        at org.apache.solr.client.solrj.impl.HttpSolrServer.request(HttpSolrServer.java:435)
        at org.apache.solr.client.solrj.impl.HttpSolrServer.request(HttpSolrServer.java:180)
        at org.apache.solr.client.solrj.request.QueryRequest.process(QueryRequest.java:90)
        at org.apache.solr.client.solrj.SolrServer.query(SolrServer.java:310)
        at au.org.ala.biocache.dao.SearchDAOImpl.runSolrQuery(SearchDAOImpl.java:1509)
        at au.org.ala.biocache.dao.SearchDAOImpl.runSolrQuery(SearchDAOImpl.java:1435)
        at au.org.ala.biocache.dao.SearchDAOImpl.access$000(SearchDAOImpl.java:78)
        at au.org.ala.biocache.dao.SearchDAOImpl$1.call(SearchDAOImpl.java:692)
        at au.org.ala.biocache.dao.SearchDAOImpl$1.call(SearchDAOImpl.java:664)
        at java.util.concurrent.FutureTask.run(FutureTask.java:262)
        ... 3 more
Caused by: org.apache.http.NoHttpResponseException: The target server failed to respond
        at org.apache.http.impl.conn.DefaultHttpResponseParser.parseHead(DefaultHttpResponseParser.java:95)
        at org.apache.http.impl.conn.DefaultHttpResponseParser.parseHead(DefaultHttpResponseParser.java:62)
        at org.apache.http.impl.io.AbstractMessageParser.parse(AbstractMessageParser.java:254)
        at org.apache.http.impl.AbstractHttpClientConnection.receiveResponseHeader(AbstractHttpClientConnection.java:289)
        at org.apache.http.impl.conn.DefaultClientConnection.receiveResponseHeader(DefaultClientConnection.java:252)
        at org.apache.http.impl.conn.ManagedClientConnectionImpl.receiveResponseHeader(ManagedClientConnectionImpl.java:191)
        at org.apache.http.protocol.HttpRequestExecutor.doReceiveResponse(HttpRequestExecutor.java:300)
        at org.apache.http.protocol.HttpRequestExecutor.execute(HttpRequestExecutor.java:127)
        at org.apache.http.impl.client.DefaultRequestDirector.tryExecute(DefaultRequestDirector.java:717)
        at org.apache.http.impl.client.DefaultRequestDirector.execute(DefaultRequestDirector.java:522)
        at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:906)
        at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:805)
        at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:784)
        at org.apache.solr.client.solrj.impl.HttpSolrServer.request(HttpSolrServer.java:365)
        ... 12 more
```
* [[org.ala.biocache.service.AuthService]](https://github.com/AtlasOfLivingAustralia/biocache-service/blob/master/src/main/java/au/org/ala/biocache/service/AuthService.java#L132)
RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
```
2015-02-19 11:30:37,053 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
 at [Source: sun.net.www.protocol.http.HttpURLConnection$HttpInputStream@2e92cded; line: 1, column: 1]; nested exception is org.codehaus.jackson.map.JsonMappingException: Can not deserialize instance of java.util.List out of START_OBJECT token
 at [Source: sun.net.www.protocol.http.HttpURLConnection$HttpInputStream@2e92cded; line: 1, column: 1]
org.springframework.web.client.ResourceAccessException: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
 at [Source: sun.net.www.protocol.http.HttpURLConnection$HttpInputStream@2e92cded; line: 1, column: 1]; nested exception is org.codehaus.jackson.map.JsonMappingException: Can not deserialize instance of java.util.List out of START_OBJECT token
 at [Source: sun.net.www.protocol.http.HttpURLConnection$HttpInputStream@2e92cded; line: 1, column: 1]
        at org.springframework.web.client.RestTemplate.doExecute(RestTemplate.java:453)
        at org.springframework.web.client.RestTemplate.execute(RestTemplate.java:401)
        at org.springframework.web.client.RestTemplate.postForObject(RestTemplate.java:279)
        at au.org.ala.biocache.service.AuthService.loadMapOfEmailToUserId(AuthService.java:132)
        at au.org.ala.biocache.service.AuthService.reloadCaches(AuthService.java:154)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:606)
        at org.springframework.util.MethodInvoker.invoke(MethodInvoker.java:273)
        at org.springframework.scheduling.support.MethodInvokingRunnable.run(MethodInvokingRunnable.java:65)
        at org.springframework.scheduling.support.DelegatingErrorHandlingRunnable.run(DelegatingErrorHandlingRunnable.java:51)
        at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:471)
        at java.util.concurrent.FutureTask.runAndReset(FutureTask.java:304)
        at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$301(ScheduledThreadPoolExecutor.java:178)
        at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:293)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
        at java.lang.Thread.run(Thread.java:744)
Caused by: org.codehaus.jackson.map.JsonMappingException: Can not deserialize instance of java.util.List out of START_OBJECT token
 at [Source: sun.net.www.protocol.http.HttpURLConnection$HttpInputStream@2e92cded; line: 1, column: 1]
        at org.codehaus.jackson.map.JsonMappingException.from(JsonMappingException.java:163)
        at org.codehaus.jackson.map.deser.StdDeserializationContext.mappingException(StdDeserializationContext.java:198)
        at org.codehaus.jackson.map.deser.CollectionDeserializer.handleNonArray(CollectionDeserializer.java:149)
        at org.codehaus.jackson.map.deser.CollectionDeserializer.deserialize(CollectionDeserializer.java:107)
        at org.codehaus.jackson.map.deser.CollectionDeserializer.deserialize(CollectionDeserializer.java:97)
        at org.codehaus.jackson.map.deser.CollectionDeserializer.deserialize(CollectionDeserializer.java:26)
        at org.codehaus.jackson.map.ObjectMapper._readMapAndClose(ObjectMapper.java:2395)
        at org.codehaus.jackson.map.ObjectMapper.readValue(ObjectMapper.java:1655)
        at org.springframework.http.converter.json.MappingJacksonHttpMessageConverter.readInternal(MappingJacksonHttpMessageConverter.java:135)
        at org.springframework.http.converter.AbstractHttpMessageConverter.read(AbstractHttpMessageConverter.java:154)
        at org.springframework.web.client.HttpMessageConverterExtractor.extractData(HttpMessageConverterExtractor.java:74)
        at org.springframework.web.client.RestTemplate.doExecute(RestTemplate.java:446)
        ... 18 more
```
This one seems to be occuring with regular frequency of every 10 minutes:
```BASH
grep 'RestTemplate error:' ./biocache-service.log

2015-02-19 11:00:19,069 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 11:10:25,575 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 11:20:31,403 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 11:30:37,053 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 11:40:43,669 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 11:50:50,354 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 12:00:56,772 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 12:11:03,334 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 12:21:10,239 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 12:31:16,201 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 12:41:22,793 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 12:51:29,485 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 13:01:35,218 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 13:11:41,979 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 13:21:48,813 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 13:31:55,560 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 13:42:02,069 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 13:52:11,145 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 14:02:17,473 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 14:12:24,063 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 14:22:30,167 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 14:32:37,936 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 14:42:44,283 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 14:52:50,470 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 15:02:50,731 [org.ala.biocache.service.AuthService] RestTemplate error: 500 Internal Server Error
2015-02-19 15:02:50,765 [org.ala.biocache.service.AuthService] RestTemplate error: 500 Internal Server Error
2015-02-19 15:02:50,792 [org.ala.biocache.service.AuthService] RestTemplate error: 500 Internal Server Error
2015-02-19 15:12:58,388 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 15:23:04,767 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 15:33:10,905 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 15:43:17,279 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 15:53:23,498 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 16:03:29,581 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 16:13:36,851 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 16:23:43,062 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 16:33:50,071 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 16:43:56,829 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 16:54:03,102 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 17:04:09,795 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 17:14:15,972 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 17:24:22,036 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 17:34:29,166 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 17:44:36,200 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 17:54:43,181 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 18:04:52,116 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 18:14:59,324 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 18:25:05,773 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 18:35:11,599 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 18:45:21,031 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
2015-02-19 18:55:27,314 [org.ala.biocache.service.AuthService] RestTemplate error: I/O error: Can not deserialize instance of java.util.List out of START_OBJECT token
...
```

####3. testing queries
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
