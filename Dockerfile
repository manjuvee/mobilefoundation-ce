ARG ARCH=amd64

FROM amd64/websphere-liberty:19.0.0.5-microProfile1 as builder
MAINTAINER IBM

USER root

# Set password length and expiry for compliance with Vulnerability Advisor
RUN sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs \
	&& sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs \
    && sed -i 's/sha512/sha512 minlen=8/' /etc/pam.d/common-password

RUN mkdir -p /opt/ibm/wlp/usr/servers/defaultServer/resources/security \
    && chown -R 1001:0 /opt/ibm/wlp/usr/servers/defaultServer/resources/security \
    && mkdir /opt/ibm/wlp/databases \
    && chown -R 1001:0 /opt/ibm/wlp/databases \
    && rm -rf /opt/ibm/wlp/usr/servers/defaultServer/configDropins/defaults \
    && chown -R 1001:0 /opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides \
    && mkdir -p /opt/ibm/MobileFirst/licenses \
    && chown -R 1001:0 /opt/ibm/MobileFirst/licenses \
    && chown -R 1001:0 /opt/ibm/wlp

USER 1001

# Copy MFP Server war files
COPY mfpf-libs/mfp-server.war  /opt/ibm/wlp/usr/servers/defaultServer/apps
COPY mfpf-libs/mfp-admin-service.war  /opt/ibm/wlp/usr/servers/defaultServer/apps
COPY mfpf-libs/mfp-admin-ui.war  /opt/ibm/wlp/usr/servers/defaultServer/apps
COPY mfpf-libs/mfp-config-service.war  /opt/ibm/wlp/usr/servers/defaultServer/apps
COPY mfpf-libs/mfp-push-service.war  /opt/ibm/wlp/usr/servers/defaultServer/apps
COPY mfpf-libs/mfp-server-swagger-ui.war  /opt/ibm/wlp/usr/servers/defaultServer/apps

#Copy Analytics ear
COPY mfpf-libs/analytics.ear  /opt/ibm/wlp/usr/servers/defaultServer/apps

#Copy Appcenter war files
COPY mfpf-libs/applicationcenter.war  /opt/ibm/wlp/usr/servers/defaultServer/apps
COPY mfpf-libs/appcenterconsole.war  /opt/ibm/wlp/usr/servers/defaultServer/apps

# Copy dropins
COPY mfpf-libs/mfp-dev-artifacts.war /opt/ibm/wlp/usr/servers/defaultServer/dropins 

COPY licenses/ /opt/ibm/MobileFirst/licenses
# Copy Precreated databases
COPY --chown=1001:0 databases/ /opt/ibm/wlp/databases
USER root
RUN chmod -R 777 /opt/ibm/wlp/databases
USER 1001

COPY config/keystore.xml /opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides
COPY server.xml /opt/ibm/wlp/usr/servers/defaultServer
COPY jvm.options /opt/ibm/wlp/usr/servers/defaultServer
COPY mfpf-libs/derby.jar /opt/ibm/wlp/usr/shared/resources
COPY bootstrap.properties /opt/ibm/wlp/usr/servers/defaultServer
# update keystore  and truststore file
COPY security/keystore.jks /opt/ibm/wlp/usr/servers/defaultServer/resources/security

FROM  ${ARCH}/websphere-liberty:19.0.0.5-kernel
MAINTAINER IBM

COPY --chown=1001:0 --from=builder /etc/login.defs /etc/login.defs
COPY --chown=1001:0 --from=builder /etc/pam.d/common-password /etc/pam.d/common-password
COPY --chown=1001:0 --from=builder /opt/ibm/wlp /opt/ibm/wlp
COPY --chown=1001:0 --from=builder /opt/ibm/MobileFirst /opt/ibm/MobileFirst

USER 1001
