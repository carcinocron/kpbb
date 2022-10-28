const { sentryHandler, Sentry } = require('./sentry');

const Parser = require('rss-parser');
const parser = new Parser({
  // headers: {'User-Agent': 'something different'},
  maxRedirects: 0,
});

const deep_rename_keys = require('deep-rename-keys');
const snake_case = require('lodash.snakecase');

// great idea for non-default strategies
// @link https://docs.rsshub.app/en/usage.html#generate-a-rss-feed

// @link https://www.npmjs.com/package/rss-converter
// @link https://www.npmjs.com/package/rss-url-parser
// @link https://www.npmjs.com/package/rss-parser

exports.fn = sentryHandler(async (req, res) => {
  // console.log('functions/inbound_feed', req.body);
  if (req.method !== 'POST') return res.send('');
  if (!(req.body && req.body.endpoints && req.body.endpoints.length > 0)) return res.send('');
  let timeoutId = null
  const fiveSeconds = new Promise(resolve => setTimeout(resolve, 5100, { timeout: true }));
  try {
    const feedPromises = req.body.endpoints.map(feed => Promise.race([fiveSeconds, new Promise(async (resolve, reject) => {
      try {
        const data = await parser.parseURL(feed.url);
        // console.log({
        //   [feed.url]: data,
        // });
        const meta = deep_rename_keys(data, snake_case);
        const items = deep_rename_keys(data.items, snake_case);
        // console.log({
        //   meta,
        //   items,
        // });
        delete meta.items;
        resolve({
          meta: JSON.stringify(meta),
          items: items.map(item => ({
            guid: item.guid || item.id || item.link,
            payload: JSON.stringify(item),
          })),
        });
      } catch (err) {
        Sentry.captureException(err);
        resolve({
          error: err,
        });
      }
    })]));
    const results = await Promise.all(feedPromises);
    // results = deep_rename_keys(results, snake_case);
    // { const keys = new Set; deep_rename_keys(results, key => (keys.add(key), key)); console.log([...keys]); }
    // console.log({results});
    // console.log({results: results[0]});
    // console.log(results[0].items[0]);
    // console.log(results[0].items.map(item => item.guid));
    res.send(JSON.stringify({results}));
  } finally {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
  }
});
