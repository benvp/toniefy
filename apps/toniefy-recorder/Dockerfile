FROM hexpm/elixir:1.14.3-erlang-25.1.2.1-ubuntu-focal-20221130

ARG CHROME_VERSION="143.0.7499.42"

ENV DEBIAN_FRONTEND=noninteractive
ENV MIX_ENV=prod

WORKDIR /usr/src/app

COPY . .

RUN apt-get update && \
  apt-get -yq --no-install-recommends install apt-utils && \
  apt-get -yq --no-install-recommends install gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic x11-apps xvfb libgbm1 libxkbcommon0 libu2f-udev libvulkan1 && \
  apt-get -yq install gnupg gnupg1 gnupg2 unzip wget curl apt-utils && \
  apt-get -yq install pulseaudio pulseaudio-utils lame sox libsox-fmt-mp3

RUN wget -q "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chromedriver-linux64.zip" && \
  unzip chromedriver-linux64.zip && \
  mv chromedriver-linux64/chromedriver /usr/local/bin/ && \
  rm -rf chromedriver-linux64*

RUN wget -q "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chrome-linux64.zip" \
  && unzip chrome-linux64.zip \
  && mv chrome-linux64 /opt/chrome \
  && ln -s /opt/chrome/chrome /usr/local/bin/google-chrome \
  && rm chrome-linux64.zip

RUN adduser root pulse-access

RUN mix local.hex --force && mix local.rebar --force && mix deps.get && mix compile

CMD ["./bin/start.sh"]
