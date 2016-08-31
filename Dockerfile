FROM sdurrheimer/alpine-glibc

# install python
RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
  && apk add --update \
              musl \
              build-base \
              bash \
              git \
              python \
              python-dev \
              py-pip \
  && pip install --upgrade pip \
  && rm /var/cache/apk/*

# make some useful symlinks that are expected to exist
RUN cd /usr/bin \
  && ln -sf easy_install-2.7 easy_install \
  && ln -sf python2.7 python \
  && ln -sf python2.7-config python-config \
  && ln -sf pip2.7 pip

# Install kubectl
RUN apk add --update -t deps curl ca-certificates \
 && curl -L https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz -o ./google-cloud-sdk.tar.gz \
 && tar zxvf google-cloud-sdk.tar.gz \
 && rm google-cloud-sdk.tar.gz \
 && ls -l \
 && ./google-cloud-sdk/install.sh --usage-reporting=true --path-update=true \
 && apk del --purge deps \
 && rm /var/cache/apk/*


# Add gcloud to the path
ENV PATH /google-cloud-sdk/bin:$PATH

# Configure gcloud for your project
RUN y | gcloud components update
RUN y | gcloud components update alpha

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
