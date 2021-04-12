/* eslint-disable @typescript-eslint/no-var-requires */

const postCssPresetEnv = require('postcss-preset-env');

module.exports = {
  plugins: [
    require('postcss-import'),
    require('tailwindcss'),
    postCssPresetEnv({
      stage: 1,
      features: {
        // needs to be disabled to be compatible with tailwind
        'focus-within-pseudo-class': false,
      },
    }),
  ],
};
