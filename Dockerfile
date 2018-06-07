# Base image on tomcat 7 with OpenJDK JRE 7
FROM tomcat:8.5.31-jre8

# Create pega directory for storing applications
RUN mkdir -p /opt/pega

# Expand prweb to target directory
COPY ./prweb.war /opt/pega/prweb.war
RUN unzip -q -d /opt/pega/prweb /opt/pega/prweb.war

# Expand pr sys managment to target directory
COPY ./prsysmgmt.war /opt/pega/prsysmgmt.war
RUN unzip -q -d /opt/pega/prsysmgmt /opt/pega/prsysmgmt.war

# Make jdbc driver available to tomcat applications
COPY ./mssql-jdbc-6.4.0.jre8.jar /usr/local/tomcat/lib/

COPY ./context.xml /opt/tomcat/conf

COPY ./server.xml /opt/tomcat/conf

COPY ./web.xml /opt/tomcat/conf

COPY ./tomcat-users.xml /opt/tomcat/conf

COPY ./setenv.sh /opt/tomcat/bin

EXPOSE 80

# Setup global database variables
ENV DB_USERNAME=pegaadmin \
    DB_PASSWORD=admin#1234 \
    DB_HOST=pegadevdb.database.windows.net \
    DB_PORT=1433 \
    DB_NAME=pegarbdb 

# Provide variables for the JDBC connection string
ENV JDBC_CLASS=com.microsoft.sqlserver.jdbc.SQLServerDriver \
    JDBC_DB_TYPE=mssql \
    JDBC_URL_PREFIX='//' \
    JDBC_URL_SUFFIX='' \
    JDBC_MIN_ACTIVE=50 \
    JDBC_MAX_ACTIVE=250 \
    JDBC_MIN_IDLE=10 \
    JDBC_MAX_IDLE=50 \
    JDBC_MAX_WAIT=30000 \
    JDBC_INITIAL_SIZE=50 \
    JDBC_VALIDATION_QUERY='SELECT 1'

# Provide variables for the name of the rules and data schema
ENV RULES_SCHEMA=PegaRULES \
    DATA_SCHEMA=PegaDATA

# Parameterize variables to customize the tomcat runtime
ENV MAX_THREADS=300 \
    INDEX_DIRECTORY=NONE \
    HEAP_DUMP_PATH=/heapdumps \
    NODE_ID=NONE
ENV JAVA_OPTS -Xms2048m -Xmx4096m -XX:PermSize=64m -XX:MaxPermSize=384m

# Configure Remote JMX support and bind to port 9001
ENV JMX_PORT=9001 \
    JMX_SERVER_HOSTNAME=127.0.0.1 \
    TOMCAT_JMX_JAR_TGZ_URL=https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/extras/catalina-jmx-remote.jar
RUN curl -kSL ${TOMCAT_JMX_JAR_TGZ_URL} -o catalina-jmx-remote.jar && \
    curl -kSL ${TOMCAT_JMX_JAR_TGZ_URL}.asc -o catalina-jmx-remote.jar.asc && \
    for key in $GPG_KEYS; do  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; done && \
    gpg --verify catalina-jmx-remote.jar.asc && \
    mv catalina-jmx-remote.jar /usr/local/tomcat/lib/catalina-jmx-remote.jar && \
    rm catalina-jmx-remote.jar.asc

# Copy in tomcat configuration and application files
COPY conf /usr/local/tomcat/conf/
COPY bin /usr/local/tomcat/bin/

# Copy in and configure customized entry point script
COPY docker-entrypoint.sh  /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]

# Expose the HTTP, SMA and JMX ports
EXPOSE 8080 8090 9001

# Expose the list of Hazelcast ports
EXPOSE 5701-5710

# Expose Ignite port
EXPOSE 47100
