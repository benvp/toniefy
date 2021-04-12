export type SpotifyPlayerWithOptions = Spotify.SpotifyPlayer & {
  _options: {
    getOAuthToken: (cb: (token: string) => void) => void;
    id: string;
  };
};
