"use strict";

const { requestOmdbAPI } = require("omdb");

exports.handler = async ({ queryStringParameters = {} }) => {
  try {
    return {
      statusCode: 200,
      body: await requestOmdbAPI(queryStringParameters),
    };
  } catch (error) {
    return {
      statusCode: 400,
      body: error,
    };
  }
};
