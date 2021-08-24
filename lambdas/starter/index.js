"use strict";

const { requestOmdbAPI } = require("omdb");

exports.handler = async ({ queryStringParameters = {} }) => {
  try {
    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET",
      },
      body: await requestOmdbAPI(queryStringParameters),
    };
  } catch (error) {
    return {
      statusCode: 400,
      body: error,
    };
  }
};
