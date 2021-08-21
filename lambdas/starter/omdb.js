const http = require("http");
const qs = require("querystring");

const { OMDB_API_KEY, OMDB_API_DOMAIN_NAME } = process.env;

exports.requestOmdbAPI = (query) => {
  const querystring = qs.encode({
    ...query,
    apikey: OMDB_API_KEY,
  });

  const url = `http://${OMDB_API_DOMAIN_NAME}/?${querystring}`;

  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let rawData = "";
      res.on("data", (c) => (rawData += c));
      res
        .on("end", () => {
          if (res.statusCode !== 200) {
            return reject(
              new Error(
                `Omdb API returned statusCode: ${res.statusCode} instead of 200. API returned response:\n${rawData}`
              )
            );
          } else {
            return resolve(rawData);
          }
        })
        .on("error", reject);
    });
  });
};
