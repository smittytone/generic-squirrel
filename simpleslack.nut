/**
 * Basic Slack message poster using the Incoming Webhook
 *
 * @author    Tony Smith (@smittytone)
 * @copyright Tony Smith, 2019
 * @licence   MIT
 * @version   1.0.1
 *
 * @class
 *
 */
class SimpleSlack {

    static VERSION = "1.0.1";
    static BASE = "https://hooks.slack.com/services/"

    _key = null;

    /**
     * Instantiate the class
     *
     * @param {string} webook - The string provided by Slack for a new webhook, eg. "T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
     *
     * @returns {instance} this
     *
     */
    constructor(webhook = null) {
        if (webhook == null || (typeof webhook != "blob" && typeof webhook != "string")) throw "SimpleSlack() requires a valid webhook path";
        _key = typeof webhook == "string" ? webhook : webhook.tostring();
    }

    /**
     * Post a message to Slack asynnchronously
     *
     * @param {string} message - The message to post
     *
     */
    function post(message = "") {
        // Check that the incoming message is good to go - report an error if it is not
        if (message == null || message.len() == 0 || typeof message != "string") {
            server.error("SimpleSlack.post() passed in invalid message string");
            return;
        }

        // Prepare and send the message to Slack asynchronously
        local body = {"text" :message,"mrkdwn":true};
        local req = http.post(BASE + _key, {"Content-type":"application/json"}, http.jsonencode(body));
        req.sendasync(_done);
    }

    /**
     * Handle any response from Slack. Currently just logs errors
     *
     * @param {table} rsp - The response from Slack
     *
     * @private
     *
     */
    function _done(rsp) {
        if (rsp.statuscode != 200) {
            server.error("Could not post message (code: " + rsp.statuscode + ")");
        }
    }
}