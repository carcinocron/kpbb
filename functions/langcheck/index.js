const { sentryHandler, Sentry } = require('./sentry');

const langcheck = require("langcheck");

// @link https://www.npmjs.com/package/langcheck

exports.fn = sentryHandler(async (req, res) => {
  console.log('functions/langcheck', req.body);
  if (req.method !== 'POST') return res.send('');
  if (!(req.body && req.body.items && req.body.items.length > 0)) return res.send('');

  const results = []
  // console.log(req.body.items)
  const promises = req.body.items.map(async item => {
    try {
      results.push({
        id: item.id,
        lang_meta: await langcheck(item.text),
      })
    } catch (err) {
      Sentry.captureException(err, {
        extra: {
          item,
        }
      });
      return {
        error: err,
      }
    }
  });
  await Promise.all(promises);
  // console.log({results})
  res.send(JSON.stringify({results}));
});
