/**
 * AWS Lambda: IoT device logs → API endpoint
 *
 * Triggered by AWS IoT Rule on topic:
 *   aromaestro/things/+/logs
 *
 * Rule query (SQL version 2016-03-23):
 *   SELECT *, topic(3) as serial FROM 'aromaestro/things/+/logs'
 *
 * The device publishes batches of log lines while a stream is active:
 *   { "s": <seq>, "d": <dropped>, "l": "line1\nline2\n..." }
 * The Rule injects `serial` via topic(3). This Lambda forwards the batch to the
 * PHP ingest endpoint, which buffers the lines for the live-logs viewer.
 *
 * Environment variables:
 *   API_URL - e.g. https://dev.aromaestro.com/index.php?route=api/diffuser_logs
 *   API_KEY - must match AWS_IOT_LAMBDA_API_KEY in config.php
 */

const API_URL = process.env.API_URL;
const API_KEY = process.env.API_KEY;

export const handler = async (event) => {
    const serial = event.serial;

    if (!serial) {
        console.error('No serial in event (topic(3) not injected by the Rule?)');
        return { statusCode: 400, body: 'No serial' };
    }

    // Forward only the fields the ingest endpoint expects. Never log raw line content.
    const body = JSON.stringify({
        serial: serial,
        s: typeof event.s === 'number' ? event.s : parseInt(event.s, 10) || 0,
        d: typeof event.d === 'number' ? event.d : parseInt(event.d, 10) || 0,
        l: typeof event.l === 'string' ? event.l : '',
    });

    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Api-Key': API_KEY,
            },
            body: body,
        });

        const responseText = await response.text();

        if (!response.ok) {
            console.error(`API returned ${response.status} for ${serial}: ${responseText}`);
            throw new Error(`API error ${response.status}`); // let Lambda retry
        }

        return { statusCode: 200, body: responseText };
    } catch (error) {
        console.error(`Failed to call API for ${serial}:`, error.message);
        throw error; // let Lambda retry
    }
};
