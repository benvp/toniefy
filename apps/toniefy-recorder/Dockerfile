FROM hexpm/elixir:1.11.2-erlang-23.2.1-ubuntu-focal-20201008

ENV DEBIAN_FRONTEND=noninteractive
ENV MIX_ENV=prod

WORKDIR /usr/src/app

COPY . .

RUN apt-get update && \
  apt-get -yq --no-install-recommends install apt-utils && \
  apt-get -yq --no-install-recommends install gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic x11-apps xvfb && \
  apt-get -yq install gnupg gnupg1 gnupg2 unzip wget curl apt-utils && \
  apt-get -yq install pulseaudio pulseaudio-utils lame sox libsox-fmt-mp3 && \
  wget https://chromedriver.storage.googleapis.com/87.0.4280.88/chromedriver_linux64.zip && \
  unzip chromedriver_linux64.zip && \
  mv chromedriver /usr/bin/chromedriver && \
  chown root:root /usr/bin/chromedriver && \
  chmod +x /usr/bin/chromedriver && \
  curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
  apt-get update && apt-get install -y google-chrome-stable

RUN adduser root pulse-access

RUN mix local.hex --force && mix local.rebar --force && mix deps.get && mix compile

CMD ["./bin/start.sh"]
