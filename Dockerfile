FROM ubuntu:18.04

ENV LANG C.UTF-8
#jdk8
RUN apt-get -q update && \
    apt-get -y --no-install-recommends install curl git gnupg software-properties-common && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x219BD9C9 && \
    apt-add-repository "deb http://repos.azul.com/azure-only/zulu/apt stable main" && \
    apt-get -q update && \
    apt-get -y --no-install-recommends install zulu-8-azure-jdk=8.38.0.13 && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/zulu-8-azure-amd64

#maven
ARG MAVEN_VERSION=3.6.1
ARG USER_HOME_DIR="/root"
ARG SHA=b4880fb7a3d81edd190a029440cdf17f308621af68475a4fe976296e71ff4a4b546dd6d8a58aaafba334d309cc11e638c52808a4b0e818fc0fd544226d952544
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

ENV PARAMS=""

ENV TZ=PRC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#source
WORKDIR /opt
#ENV http_proxy http://10.17.255.19:8080
#ENV https_proxy http://10.17.255.19:8080
RUN git clone https://github.com/xuxueli/xxl-job.git
ENV http_proxy ""
ENV https_proxy ""
#redis-cli mysql-client
RUN apt-get -q update && \
    apt-get -y --no-install-recommends install fontconfig vim nodejs npm redis-server mysql-client && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8080


COPY application.properties /opt/xxl-job/xxl-job-admin/src/main/resources/application.properties
COPY executor.properties /opt/xxl-job/xxl-job-executor-samples/xxl-job-executor-sample-springboot/src/main/resources/application.properties

#build
WORKDIR /opt/xxl-job
RUN mvn clean install

ENTRYPOINT ["sh","-c","java -jar /opt/xxl-job/xxl-job-admin/target/xxl-job-admin-2.1.1-SNAPSHOT.jar $PARAMS"]
