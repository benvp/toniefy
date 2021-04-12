import invariant from 'tiny-invariant';

import { SpotifyPlayerWithOptions } from './types/spotify';

type PlayerInitResult = {
  deviceId: string;
  player: SpotifyPlayerWithOptions;
};

type PlayerInfo = {
  uri: string;
  token: string;
};

type PlayerError = {
  error?: boolean;
  message?: string;
};

const getPlayerInfo = (): PlayerInfo | undefined => {
  const info = document.getElementById('player-info')?.dataset.info;
  return info ? JSON.parse(info) : undefined;
};

type PlayerState = {
  uri?: string;
  currentTrack?: Spotify.Track;
  duration?: number;
  position?: number;
  paused?: boolean;
};

const getPlayerState = (): PlayerState | undefined => {
  const state = document.getElementById('player-state')?.dataset.state;
  return state ? JSON.parse(state) : undefined;
};

const getPlayerError = (): PlayerError | undefined => {
  const state = document.getElementById('player-error')?.dataset.error;
  return state ? JSON.parse(state) : undefined;
};

const setPlayerError = (error: PlayerError) => {
  const elem = document.getElementById('player-error');

  invariant(elem, 'player-error element must be present');

  elem.dataset.error = JSON.stringify(error);
};

const setPlayerState = (spotifyState: Spotify.PlaybackState) => {
  const currentTrack = spotifyState?.track_window?.current_track;

  const state: PlayerState = {
    uri: currentTrack?.uri,
    currentTrack,
    duration: spotifyState?.duration,
    position: spotifyState?.position,
    paused: spotifyState?.paused,
  };

  const elem = document.getElementById('player-state');

  invariant(elem, 'player-state element must be present');

  elem.dataset.state = JSON.stringify(state);
};

const determineUriType = (uri: string): 'context_uri' | 'uri' | 'not_supported' => {
  const contextUriRegex = /^spotify:(album|playlist):.+$/;
  const trackUriRegex = /^spotify:track:.+$/;

  if (contextUriRegex.test(uri)) {
    return 'context_uri';
  }

  if (trackUriRegex.test(uri)) {
    return 'uri';
  }

  return 'not_supported';
};

const initPlayer = () =>
  new Promise<PlayerInitResult>((resolve, reject) => {
    window.onSpotifyWebPlaybackSDKReady = () => {
      const player = new Spotify.Player({
        name: 'Toniefy',
        getOAuthToken: cb => {
          const toniefyToken = getPlayerInfo()?.token;

          return fetch('/record/token', {
            headers: {
              Authorization: toniefyToken ?? '',
            },
          })
            .then(r => r.json())
            .then(data => cb(data.service_token))
            .catch(() =>
              setPlayerError({ error: true, message: 'Unable to fetch service token.' }),
            );
        },
      });

      player.addListener('initialization_error', reject);
      player.addListener('authentication_error', reject);
      player.addListener('account_error', reject);
      player.addListener('playback_error', reject);

      player.addListener('player_state_changed', setPlayerState);

      player.addListener('ready', ({ device_id }) => {
        resolve({ deviceId: device_id, player: player as SpotifyPlayerWithOptions });
      });

      void player.connect();
    };
  });

type PlayOptions = {
  uri: string;
  player: SpotifyPlayerWithOptions;
};

void initPlayer().then(({ deviceId, player }) => {
  const uri = getPlayerInfo()?.uri;

  invariant(uri, 'Must provide a track uri.');

  const uriType = determineUriType(uri);

  invariant(
    uriType !== 'not_supported',
    'Unsupported uri type. Only tracks, playlists and albums are supported',
  );

  const play = ({ uri, player }: PlayOptions) => {
    player._options.getOAuthToken(access_token => {
      const body = uriType === 'context_uri' ? { context_uri: uri } : { uris: [uri] };

      void fetch(`https://api.spotify.com/v1/me/player/play?device_id=${deviceId}`, {
        method: 'PUT',
        body: JSON.stringify(body),
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${access_token}`,
        },
      });
    });
  };

  void play({
    uri,
    player,
  });
});
