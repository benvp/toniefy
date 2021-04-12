/* eslint-disable @typescript-eslint/no-var-requires */
const path = require('path');

const CopyWebpackPlugin = require('copy-webpack-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const glob = require('glob');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = (env, options) => {
  const devMode = options.mode !== 'production';

  return {
    entry: {
      app: glob.sync('./vendor/**/*.js').concat(['./src/app.ts']),
      record: './src/record.ts',
    },
    output: {
      filename: '[name].js',
      path: path.resolve(__dirname, '../priv/static/js'),
      publicPath: '/js/',
    },
    resolve: {
      extensions: ['.ts', '.tsx', '.js', '.json'],
    },
    module: {
      rules: [
        {
          test: /\.(ts|js)x?$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
          },
        },
        {
          test: /\.[s]?css$/,
          use: [MiniCssExtractPlugin.loader, 'css-loader', 'postcss-loader'],
        },
      ],
    },
    plugins: [
      new MiniCssExtractPlugin({ filename: '../css/app.css' }),
      new CopyWebpackPlugin({
        patterns: [
          { from: 'static/', to: '../' },
          {
            from: './node_modules/@fortawesome/fontawesome-free/css/all.min.css',
            to: '../css/fa.css',
          },
          {
            from: './node_modules/@fortawesome/fontawesome-free/webfonts',
            to: '../webfonts',
          },
        ],
      }),
    ],
    optimization: {
      minimizer: ['...', new CssMinimizerPlugin()],
    },
    devtool: devMode ? 'source-map' : undefined,
  };
};
