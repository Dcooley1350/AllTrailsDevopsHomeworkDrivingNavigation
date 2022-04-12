# AllTrails DevOps Homework: Driving Navigation

CONTENTS OF THIS FILE
---------------------

 * Introduction
 * Requirements
 * Installation
 * Using the API
 * Strategy for Production Deployment
 * Strategy for Testing
 * Woes, Laments, and What Could Have Been

INTRODUCTION
------------
This repository is intended to be used to deploy and test a driving-navigation service api to a Kubernetes cluster. It contains the necessary .yaml files to create Kubernetes deployments and services, as well as a couple of helper scripts to assist in deployment.

Deployed components include:
  * An NGINX reverse proxy that serves as the access point for the api.
  * Config Map that houses NGINX configuration and is consumed by the NGINX reverse proxy.
  * The driving directions service itself.
  * An echo server that sits in place of an actual backend application and assists in testing the reverse proxy.

![Diagram of Driving Navigation Application](https://github.com/Dcooley1350/AllTrailsDebopsHomeworkDrivingNavigation/blob/d84d13be90520a7b9849c4c64565b7b700446423/drivingNavigationDiagram.png)

REQUIREMENTS
------------

* Adminstrative access to a Kubernetes cluster with at least one node.
* kubectl CLI to interact with your cluster.
* git CLI to clone repository (alternatively, download repository from github)

INSTALLATION
------------
1. Clone repository:  
```
git clone https://github.com/Dcooley1350/AllTrailsDebopsHomeworkDrivingNavigation.git
```

2. Use terminal to navigate to root of repository  
3. From your terminal, create driving-directions namespace and deploy components by running:  
```
./deployDrivingNavigation.sh
```

USING THE API
-------------
The Kubernetes yamls in this repo are designed to expose the driving navigation service as a node port at port 30000. You can reach the driving navigation service at "http://${YOUR_NODE}:30000/directions". If you are using a local Kubernetes cluster in Docker Desktop, as I was when developing, your machine is the node, and so 'localhost' can be used in place of node IP. The remainder of this documentation assumes YOUR_NODE=localhost.

http calls to any other path on the host at port 30000 should return an echo of the request sent. This is because the NGINX reverse proxy is routing all paths EXCEPT /directions to the echo server. This is to aid in debugging and testing of the reverse proxy.

### GET -  /directions

Required Parameters: START, END (strings, eg.: 8.681495,49.41461)

Get a basic driving route between two points. Returned response is in GeoJSON format. This method does not accept any request body or parameters other than start coordinate, and end coordinate. The API requires no authentication.  

Example: http://localhost:30000/directions?start=8.681495,49.41461&end=8.687872,49.420318

Test:
* From outside Kubernetes cluster, run from terminal:
```
curl 'http://localhost:30000/directions?start=8.681495,49.41461&end=8.687872,49.420318'
```

Expected response:
```
{"type":"FeatureCollection","metadata":{"attribution":"openrouteservice.org, OpenStreetMap contributors","service":"routing","timestamp":1649781824432,"query":{"coordinates":[[8.681495,49.41461],[8.687872,49.420318]],"profile":"driving-car","format":"json"},"engine":{"version":"6.7.0","build_date":"2022-04-12T02:40:06Z","graph_date":"2022-04-12T02:43:52Z"}},"features":[{"bbox":[8.681445,49.41461,8.690123,49.420514],"type":"Feature","properties":{"segments":[{"distance":1365.3,"duration":315.2,"steps":[{"distance":312.2,"duration":74.9,"type":11,"instruction":"Head north on Wielandtstraße","name":"Wielandtstraße","way_points":[0,6]},{"distance":253.2,"duration":60.8,"type":1,"instruction":"Turn right onto Mönchhofstraße","name":"Mönchhofstraße","way_points":[6,13]},{"distance":213.2,"duration":51.2,"type":0,"instruction":"Turn left onto Keplerstraße","name":"Keplerstraße","way_points":[13,14]},{"distance":372.9,"duration":89.5,"type":1,"instruction":"Turn right onto Moltkestraße","name":"Moltkestraße","way_points":[14,20]},{"distance":83.0,"duration":7.5,"type":0,"instruction":"Turn left onto Handschuhsheimer Landstraße, B 3","name":"Handschuhsheimer Landstraße, B 3","way_points":[20,22]},{"distance":130.8,"duration":31.4,"type":0,"instruction":"Turn left onto Roonstraße","name":"Roonstraße","way_points":[22,25]},{"distance":0.0,"duration":0.0,"type":10,"instruction":"Arrive at Roonstraße, straight ahead","name":"-","way_points":[25,25]}]}],"way_points":[0,25],"summary":{"distance":1365.3,"duration":315.2}},"geometry":{"coordinates":[[8.681495,49.41461],[8.681445,49.415755],[8.681509,49.416087],[8.681674,49.4166],[8.681815,49.417079],[8.681873,49.417276],[8.681882,49.417391],[8.682107,49.41739],[8.682461,49.417389],[8.68269,49.417388],[8.682782,49.417388],[8.683596,49.417386],[8.684681,49.417373],[8.685382,49.417368],[8.68504,49.419273],[8.686507,49.41943],[8.687109,49.419488],[8.6883,49.41962],[8.688398,49.41963],[8.690104,49.419828],[8.690123,49.419833],[8.689854,49.420216],[8.689652,49.420514],[8.68963,49.42051],[8.688601,49.420393],[8.687872,49.420318]],"type":"LineString"}}],"bbox":[8.681445,49.41461,8.690123,49.420514]}
```

* To test API endpoint from inside the cluster, you can deploy a test pod and send a request to the endpoint by issuing the command  
```
kubectl run curl-test --image=curlimages/curl -n driving-navigation -i --tty --rm --restart=Never --command -- curl 'http://nginx-rp/directions?start=8.681495,49.41461&end=8.687872,49.420318'
```

This comand will start a curl pod inside the same namespace as the driving directions service. It will then use the name of the service that exposes the nginx reverse proxy as the host name to send a get request to the driving directions service. The pod will remain in the foreground of your terminal and return responses. The pod will clean itself up after it is done running.

STRATEGY FOR PRODUCTION DEPLOYMENT
----------------------------------
To deploy this configuration into production, I would deploy it along-side the active production infrastructure, then run integration tests and possiblly QA against it before I routed actual user traffic to it. There are many ways to do this. Kubernetes ingress or virtual services are an option. You could put an istio virtual service in-front of the reverse proxy and only route traffic that matches a certain pattern to the reverse proxy. This way your QA team could use a new web client that expects the directions-service to be there to test the directions-service while all other actuall production traffic uses the infra without the reverse proxy and the directions-service. You could also accomplish this with akamai router and probably AWS Route53, though I have not ever used Route53 in this way.  
There are many ways to accomplish this, but the idea is the same. I would deploy the new services to production along-side the old services, ensuring that actual production users can use the old services while the new services are extensively tested. I would then route production traffic to the new services slowly(perhaps by geographic location), monitoring for alerts of bad behaior. Ensuring easy rollback to previous version of services is also important, but probably beyond the scope here.

STRATEGY FOR TESTING
--------------------
To test this directions service and reverse proxy implementation I would create a couple of suites of automated integration tests that ran during every deployment, as well as an extended load test that ran regularly(nightly? weekly?). The integration tests should run http requests against all endpoints in the directions service. The tests should also cover all basic functionality of the reverse proxy, such as https termination, routing based on path, etc. The integration test suites should be run in a couple of test environments before the configuration is deployed into production. Once the configuration is deployed into production, integration tests should be run against the services before production traffic is routed to the services. (see Strategy for Production Deployment)
If the directions service was an in-house service, rather than Open Route Service software, I would also require unit test suites with extensive coverage that run continuous during CI. (Since we are using Open Route Source here, we kind of have to trust that the software is tested and reliable.)

WOES, LAMENTS, AND WHAT COULD HAVE BEEN
---------------------------------------

It was very tempting to spend another 5 hours on this. It is hard for me to put things down when I consider them half finished. It is also very hard for me to say to myself "Hey you need at least on hour of this time to write the README, so stop developing and start writing". Being honest about time, I probably spent 2.5 hours developing, and another 2 hours writing. I expected to only spend a half hour writing, but there was a lot that I did not get to show in development that I wanted to say in my README.

Areas I struggled:

 * I initially did not understand that the default .osm file that is included in the stock Open Route Service docker image is the heidelberg.osm. I wasted some time writing a script to download the heidelberg.osm.gz, unpack it, and convert it with osmium command line tool. The script downloadUnpackOSM.sh is not needed, but I included it anyway, as I spent project time writing it. *Face-Palm*

* Creating the Kubernetes yaml for the Open Route Service deployment, I initially tried to use persistent volumes for data, as the Open Route Service documentation suggests. I am developing in a WSL, local Docker Desktop Kubernetes environment, which it turns out, does not yet support local persistent volumes. It took me a while to figure this out, and I spent a decent amount of time trying to make workarounds function before I just dropped it and used empty-dirs for my volumes. *Double Face-Palm*

If I had more time:

* My nginx conf works. It works. Is it optimized? No. Does it contain some superflous stuff for the current application? Yes. I would have dialed this conf in to do exactly what I need it to do in this application.  

* I did not have time to implement ssl. The fast hacks that I could think of off the top of my head would have meant committing certs to source control, which is a no-no. If I had more time, I would have written some little script that did something like this for the user:  
  1. Create a template configmap yaml with fields for cert and key. (This would just be a pre-written template)
  2. Use linux CL tool openssl to create self signed cert and key.
  3. Use linux CL tool such as yq or envsubst to put key and cert into template config map.
  4. Apply configmap .yaml to create configmap in cluster.
  4. Use configmap volumes to mount the values in this configmap into the nginx reverse proxy as files in appropriate locations.
  5. Configure nginx to be able to able to handle ssl.

* My Kubernetes services are very basic, and do not scale. If I had more time, I would have implemented a load balancer service for both the nginx reverse proxy, and the direction service. I could have done that by just changing the type of the service, but it seemed hacky and superfluous when the reverse proxy and the directions service would not actually automatically scale up anyway. Given more time, I would make sure I was collecting metrics from both the reverse proxy and the directions service and implement horizontal pod autoscaling on whatever metric turned out to be the bottleneck for the component. Then I would implement loadbalancer services for the NGINX reverse proxy and the driving navigation service.

* My infrastructure does not handle security. Beside the ssl issue noted above, there is also the issue of authentication. The current infrastructure does not require any authentication before a user can access the directions service. The nginx reverse proxy could be configured to handle auth headers of whatever flavor was being used. Reroute to the rails app for authentication if the client is not able to provide valid credential(cookie, oauth token, username:pass, ...).  
  The question of 'valid' is an interesting one, though. How does the nginx reverse proxy know what a 'valid' credential is? It could be relatively stupid and check whether the auth header has a certain pattern or matches a key before allowing a request to pass to the directions service. This pattern could be rotated regularly so that an authorization will only pass the nginx header screen for a certain amount of time. 
  Truth is that I really don't know how to do this because I have never faced this issue. How do you intelligently filter traffic based on auth with a component that does not have direct knowledge of who is authenticated and who is not? I will do some research on this so that I can talk knowledgably about it with whoever reviews this work.

Note: I don't know think that I would adjust this application to handle a OSM file of 451 MB. From Open Route Service docs:  
```
One thing to be aware of is the size of the data and how much RAM is given to Java inside the container. We generally recommend at least twice the amount of RAM as the file size, but to tell Java this, you need to update the JAVA_OPTS in the environment section of the docker-compose file. In that line, you will see the -Xms1g and -Xmx2g items. These tell Java that it should start with 1GB RAM assigned to it, and go no higher than 2 GB of usage. If your pbf file is 1.5 GB in size then you would update the -Xmx item to be AT LEAST -Xmx3g. In general, we would recommend adding a bit more to the RAM value if possible to reduce the chances of hitting an out of memory exception towards the end of the graph building.
```
The current values that the documentation suggests running the Open Route Source application with already satisfy this requirement(-Xms1g -Xmx2g). I do not currently have resource requests in my kubernetes yamls, so I would definitely add those to ensure that these resources are available to the running application.
