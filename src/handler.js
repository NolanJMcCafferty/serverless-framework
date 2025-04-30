'use strict';

module.exports.hello = async (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: 'Hello world 5!',
        input: event,
      },
      null,
      2
    ),
  };
};