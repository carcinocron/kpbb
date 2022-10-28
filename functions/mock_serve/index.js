const { sentryHandler, Sentry } = require('./sentry');

// this function is not actually a function,
// only the static files in public/ are used

exports.fn = sentryHandler(async (req, res) => {
  if (req.method !== 'GET') return res.send('');
  console.log('req', req.path);
  res.send('');
});
