// Used by Jest and ESLint. The production and development bundles are built by
// Vite, which compiles JSX and decorators with config/vite/plugin-mastodon-babel.mts.
module.exports = (api) => {
  const env = api.env();

  const reactOptions = {
    development: env === 'development',
  };

  const envOptions = {
    loose: true,
    modules: env === 'test' ? 'commonjs' : false,
    debug: false,
  };

  return {
    presets: [
      ['@babel/react', reactOptions],
      ['@babel/env', envOptions],
    ],
    plugins: [
      ['@babel/proposal-decorators', { legacy: true }],
      ['react-intl', { messagesDir: './build/messages' }],
    ],
  };
};
