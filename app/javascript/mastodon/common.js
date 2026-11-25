import Rails from '@rails/ujs';

export function start() {
  try {
    Rails.start();
  } catch (e) {
    // If called twice
  }
};
