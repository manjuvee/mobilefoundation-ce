#Mobile Foundation CE image on Kube.

This repository holds the code for the IBM Mobile Foundation CE image creation and Deploy the same to the kube cluster.

## Prerequisites

1. Docker.
2. Maven.
3. Kubectl.
4. ibmcloud.
5. Connected to IBM Network.

## A. Clone the git project and build the docker image.

  1. Open the terminal and clone the git project.

	```
	git clone git@github.com:manjuvee/mobilefoundation-ce.git
	```

  2. Run the Maven command to build the docker image.

  	```
  	mvn clean install -Pdev -s maven-settings.xml

  	```

## B. Testing the docker image before pushing to the kube.

    1. Run the docker image by executing the below command.
    	```
        docker run -d -p 9080:9080 -p 9443:9443 ibm-mobilefoundation-ce:1.1.0-amd64
    	```
    2. Open the browser and test the below mobile foundation server, Application center and analytics.

       ```
       http://localhost:9080/mfpconsole
       http://localhost:9080/applicationcenter
       ```

## C. Pushing the docker image to the kube.

  1. Login to the bluemix where the free cluster is available.
    ```
      ibmcloud login
    ```
  2. Get the list of clusters.
    ```
      ibmcloud cs get clusters

    ```
  3. Get the kube cluster config.
  ```
    ibmcloud cs cluster-config <<Cluster name>>

  ```
  4. Set the cluster-config on the terminal. i.e the o/p of the step C 3
```
  Ex :
  export KUBECONFIG=/Users/manjunath/.bluemix/plugins/container-service/clusters/mycluster/kube-config-hou02-mycluster.yml
  ```
  5. Tag and push the docker image to the bluemix registry.

  ```
	docker tag <image-id-from-local-docker-registry> <registryurl>/<<namespace>/<mf-image-name>:<image-tag>
	docker push <registryurl>/<<namespace>/<mf-image-name>:<image-tag>

	Example:
	docker tag 0fb26f65ffb2 us.icr.io/manju1/ibm-mobilefoundation-ce:1.0.0
	docker push us.icr.io/manju1/ibm-mobilefoundation-ce:1.0.0
	```
  6. Create a mfpf-deploy.yaml for creating Service and Deployment by updating the image url in the below yaml.

```
vi mfpf-deploy.yaml
```  
```
apiVersion: v1
kind: Service
metadata:
  name: mfpserver
  namespace: default
  labels:
    app: mfpserver
spec:
  type: NodePort
  selector:
    app: mfpserver
  ports:
   - protocol: TCP
     port: 9080
     name: tcp-9080
   - protocol: TCP
     port: 9443
     name: tcp-9443
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: mfpserver
  namespace: default
spec:
  replicas: 1
  template:
    metadata:
      name: mfpserver
      labels:
        app: mfpserver
    spec:
      containers:
        - name: mfpserver
          image: <registryurl>/<namespace>/<mf-image-name>
          tag: <image-tag>
          imagePullPolicy: Always
          volumeMounts:
      imagePullSecrets:
        - name: bluemix-default-secret
---
```
7. Create Service and Deployment for the Mobile Foundation Server.

```
kubectl create -f mfpf-deploy.yaml
```
## D. Accessing the Mobile Foundation Console and Application Center Console.
1. As it the Mobile Foundation Server service uses the NodePort, we can obtain the ip address and port as below :

   a. Obtaining the IP address :
   ```
   ibmcloud cs workers --cluster <Cluster name>

   ```
   b. Obtaining the Port number :
   ```
   kubectl get services
   ```

   c. Combining the IP address and Port number we can form the Mobile Foundation Console URL

   ```
   http://173.193.102.104:32680/mfpconsole
   ```
   d. For Application Center

   ```
   http://173.193.102.104:32680/applicationcenter
   ```
   > NOTE: Login credentials for console is admin/admin .
