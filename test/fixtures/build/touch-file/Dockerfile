FROM umweltdk/node:0.12-onbuild
USER root
RUN  cp -R /usr/src/app /usr/src/app-copy \
  && rm -r /usr/src/app \
  && mv /usr/src/app-copy /usr/src/app \
  && chmod -R 0700 /usr/src/app \
  && chown -R app:app /usr/src/app
USER app

RUN id && ls -laZ . && touch muh/hello.ls

EXPOSE 8080

