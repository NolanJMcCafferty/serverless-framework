'use strict';

module.exports.hello = async (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: 'Hello world 4!',
        input: event,
      },
      null,
      2
    ),
  };
};