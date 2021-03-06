#- # Ping Identity Docker Image - `pingdataconsole`
#- 
#- This docker image provides a tomcat image with the PingDataConsole
#- deployed to be used in configuration of the PingData products.
#-
#- ## Related Docker Images
#- - `pingidentity/pingdownloader` - Image used to download ping product
#- - `tomcat:8-jre8-alpine` - Tomcat engine to serve PingDataConsole .war file
#-

FROM pingidentity/pingdownloader as staging
ARG PRODUCT=pingdirectory
ARG VERSION=7.2.0.1
# copy your product zip file into the staging image
RUN /get-bits.sh --product ${PRODUCT} --version ${VERSION} \
	&& unzip -d /tmp/ /tmp/product.zip PingDirectory/resource/admin-console.zip \
	&& unzip -d /opt/ /tmp/PingDirectory/resource/admin-console.zip admin-console.war \
    && mv /opt/admin-console.war /opt/console.war

#
# the final image 
#
FROM tomcat:8-jre8-alpine
LABEL	maintainer=devops_program@pingidentity.com \
		license="Ping Identity Proprietary" \
		vendor="Ping Identity Corp." \
		name="Ping Identity PingDataConsole (Alpine/OpenJDK8) Image"
EXPOSE 8080 8443
RUN apk --no-cache add curl ca-certificates \
    && keytool -genkey -keystore /usr/local/tomcat/conf/ss.jks -alias server-cert -storepass 2FederateM0re -keyalg  RSA -keysize 4096 -keypass 2FederateM0re -validity 731 -dname cn=pingdataconsole,ou=docker,o=pingidentity,l=denver,st=co,c=us
COPY --from=staging /opt/console.war /usr/local/tomcat/webapps/
COPY index.html /usr/local/tomcat/webapps/ROOT/
COPY server.xml /usr/local/tomcat/conf/
COPY [ "liveness.sh", "/usr/local/bin/" ]
HEALTHCHECK --interval=31s --timeout=30s --start-period=5s --retries=3 CMD [ "/usr/local/bin/liveness.sh" ]
CMD ["catalina.sh","run"]

#- ## Run
#- To run a PingDataConsole container: 
#- 
#- ```shell
#-   docker run \
#-            --name pingdataconsole \
#-            --publish 8080:8080 \
#-            --detach \
#-            pingidentity/pingdataconsole
#- ```
#- 
#- 
#- Follow Docker logs with:
#- 
#- ```
#- docker logs -f pingdataconsole
#- ```
#- 
#- If using the command above with the embedded [server profile](../server-profiles/README.md), log in with: 
#- * http://localhost:8080/console/login
#- ```
#- Server: pingdirectory
#- Username: administrator
#- Password: 2FederateM0re
#- ```
#- >make sure you have a PingDirectory running
