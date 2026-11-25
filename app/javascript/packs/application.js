import loadPolyfills from '../mastodon/load_polyfills';
import { start } from '../mastodon/common';
import main from '../mastodon/main';

start();

loadPolyfills().then(() => {
  main();
}).catch(e => {
  console.error(e);
});
