import React from 'react';
import ReactDOM from 'react-dom';
import loadPolyfills from '../mastodon/load_polyfills';
import { start } from '../mastodon/common';
import ready from '../mastodon/ready';
import ComposeContainer from '../mastodon/containers/compose_container';

start();

function loaded() {
  const mountNode = document.getElementById('mastodon-compose');

  if (mountNode !== null) {
    const props = JSON.parse(mountNode.getAttribute('data-props'));
    ReactDOM.render(<ComposeContainer {...props} />, mountNode);
  }
}

function main() {
  ready(loaded);
}

loadPolyfills().then(main).catch(error => {
  console.error(error);
});
