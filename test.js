// CONSTANTS
// Replace the 'USERNAME' and 'PASSWORD' values with your own
const USERNAME = '...';
const PASSWORD = '...';
const API_URL = 'api.electricimp.com';
const API_VER = '/v5/';

var https = require('https');
var device = '...';
var accessToken = '...';

function setOptions(verb, path, token) {
  // Returns an HTTPS request options object primed for API usage
  return {
    hostname: API_URL,
    path: API_VER + path,
    method: verb,
    headers: {
      'Content-Type': 'application/vnd.api+json',
      'Authorization': 'Bearer ' + token
    }
  };
}

function initStream() {
  // Set up request
  let req = http.request(setOptions('POST', 'logstream', acccesToken), (resp) => {
    let body = '';
    resp.setEncoding('utf8');
    resp.on('data', (chunk) => { body += chunk; });
    resp.on('end', () => {
      if (body.length > 0) {
      
      } else {
        // HTTP Error
        showError(resp);
      }
    });
  });
 }
