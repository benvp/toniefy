/* eslint-disable @typescript-eslint/no-var-requires */

const defaultTheme = require('tailwindcss/defaultTheme');

const brand = {
  100: 'hsl(360,100%,95%)',
  200: 'hsl(360,86%,84%)',
  300: 'hsl(360,90%,78%)',
  400: 'hsl(360,100%,71%)',
  500: 'hsl(360,95%,64%)',
  600: 'hsl(360,82%,46%)',
  700: 'hsl(360,91%,31%)',
  800: 'hsl(360,88%,22%)',
  900: 'hsl(360,82%,16%)',
};

const gray = {
  100: 'hsl(360,13%,97%)',
  200: 'hsl(360,13%,94%)',
  300: 'hsl(360,13%,85%)',
  400: 'hsl(360,13%,75%)',
  500: 'hsl(360,13%,50%)',
  600: 'hsl(360,13%,40%)',
  700: 'hsl(360,13%,25%)',
  800: 'hsl(360,13%,15%)',
  900: 'hsl(360,13%,7%)',
};

const blue = {
  100: 'hsl(193, 77%, 95%)',
  200: 'hsl(193, 70%, 90%)',
  300: 'hsl(193, 77%, 80%)',
  400: 'hsl(193, 71%, 66%)',
  500: 'hsl(193, 77%, 45%)',
  600: 'hsl(193, 73%, 36%)',
  700: 'hsl(193, 66%, 22%)',
  800: 'hsl(193, 80%, 13%)',
  900: 'hsl(193, 88%, 8%)',
};

module.exports = {
  purge: [
    '../**/*.html.eex',
    '../**/*.html.leex',
    '../**/views/**/*.ex',
    '../**/live/**/*.ex',
    './src/**/*.{js,ts,tsx}',
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: {
        primary: {
          main: brand[500],
          ...brand,
        },
        gray,
        blue,
        error: defaultTheme.colors.red[700],
      },
      fontFamily: {
        sans: ['Nunito', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  variants: {
    extend: {
      borderWidth: ['hover'],
    },
  },
  plugins: [require('@tailwindcss/forms')],
};
