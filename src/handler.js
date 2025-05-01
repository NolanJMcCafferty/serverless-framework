'use strict';

module.exports.hello = async (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: 'Hello world v2!',
        input: event,
      },
      null,
      2
    ),
  };
};