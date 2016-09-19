FROM umweltdk/php:0.12-onbuild
USER root
RUN  cp -R /var/www/html /var/www/html-copy \
  && rm -r /var/www/html \
  && mv /var/www/html-copy /var/www/html \
  && chmod -R 0700 /var/www/html \
  && chown -R app:app /var/www/html
USER app

RUN id && ls -laZ . && touch muh/hello.ls

