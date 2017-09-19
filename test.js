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
  let req = https.request(setOptions('POST', 'logstream', acccesToken), (resp) => {
    let body = '';
    resp.setEncoding('utf8');
    resp.on('data', (chunk) => { body += chunk; });
    resp.on('end', () => {
      if (body.length > 0) {
        try {
          let data = JSON.parse(body);
          data = data.data;
          if (resp.statusCode === 200) {
            let url = data.attributes.url;
            beginStream(url);
          } else {
            // API Error
            console.log(`API ERROR: ${data.code} (${data.message}`);
          }
        } catch (err) {
          console.log(err);
        }
      } else {
        // HTTP Error
        showError(resp);
      }
    });
  });
  
  // Send request
  req.end();
}

function beginStream(url) {
  // Set up stream
  let urlarray = url.split('//');
  urlarray = urlarray[1].split('/');
  let path = '';
  for (part of urlarray) {
    path = path + part + '/';
  }

  let req = https.request(setOptions('GET', url, accessToken), (resp) => {
    let body = '';
    resp.setEncoding('utf8');
    resp.on('data' (chunk) => { data += chunk; });
    resp.on('end', () => {
      if (resp.statusCode === 200) {
        // Add device to stream
        addDevice(path, device);
      }
    });
  });

  req.end();
}

function addDevice(path, id) {
  let req = https.request(setOptions('PUT', path + id, accessToken), (resp) => {
    let body ='';
    resp.setEncoding('utf8');
    resp.on('data', (chunk) => { body += chunk });
    resp.on('end', () => {
      try {
        let data = JSON.parse(body);
        data = data.data;
        if (data.event === 'message') {
          console.log(data.data);
        }
      } catch (err) {
        console.log(err);
      }
    });
  });

  req.write(JSON.stringify({
    'id': id,
    'type': 'device'
  }));

  req.end();
}

// RUNTIME
initStream();
