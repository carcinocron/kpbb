const Sentry = require('@sentry/node')
if (process.env.APP_GOOGLE_CLOUD) {
  require('@google-cloud/debug-agent').start()
}

Sentry.init({
  dsn: process.env.SENTRY_DSN
});

function sentryHandler(lambdaHandler) {
  return async (...args) => {
    try {
      return await lambdaHandler(...args);
    } catch (error) {
      Sentry.captureException(error);
      await Sentry.flush(2000);
      throw error;
    }
  };
}

exports.sentryHandler = sentryHandler;
exports.Sentry = Sentry;
