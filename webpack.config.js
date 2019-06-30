const path = require('path');

// const webpack = require('webpack');
// const HtmlWebpackPlugin = require('html-webpack-plugin');
// const CleanWebpackPlugin = require('clean-webpack-plugin');

module.exports = {
  entry: {
    app: './src/app_renderer.tsx'
  },
  devtool : 'source-map',
  mode: 'development',
  output: {
    filename: 'renderer.js',
    path: path.resolve(__dirname, 'build')
  },
  // https://stackoverflow.com/a/48476887/1804173
  target: 'electron-renderer',
  module: {
    rules: [
      //{test: /\.tsx?$/, loader: 'ts-loader' }
      /*
      {
        test: [/\.jsx?$/, /\.tsx?$/],
        use: 'babel-loader',
        exclude: /node_modules/,
        options: {
          presets: ['@babel/preset-env'],
          plugins: [
            'jsx-dom-expressions',
            '@babel/plugin-proposal-object-rest-spread',
            '@babel/plugin-proposal-class-properties'
          ]
        }
      }
      */
      {
        test: [/\.jsx?$/, /\.tsx?$/],
        include: path.resolve(__dirname, 'src'),
        use: {
          loader: 'babel-loader',
        },
      },
    ]
  },
  resolve: {
    extensions: [ '.ts', '.tsx', '.js' ]
  },
  plugins: [
    // https://webpack.js.org/guides/hot-module-replacement
    // new CleanWebpackPlugin(),
    // new HtmlWebpackPlugin({
    //   title: 'Hot Module Replacement'
    // }),
    // new webpack.HotModuleReplacementPlugin()
  ],
  optimization: {
    minimize: false
  },
  devServer: {
    contentBase: path.join(__dirname, 'dist'),
    watchContentBase: true,
    //disableHostCheck: true,
    //hot: true,
    //inline: true,
  }
};
