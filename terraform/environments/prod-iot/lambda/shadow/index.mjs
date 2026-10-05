/**
 * AWS Lambda: IoT Shadow → API endpoint
 *
 * Triggered by AWS IoT Rule on topic:
 *   $aws/things/+/shadow/update/documents
 *
 * Rule query:
 *   SELECT *, topic() AS topic FROM '$aws/things/+/shadow/update/documents'
 *
 * Extracts the delta between previous and current reported state,
 * then POSTs it to the PHP API endpoint.
 *
 * Environment variables:
 *   API_URL     - e.g. https://dev.aromaestro.com/index.php?route=api/diffuser_mqtt_shadow
 *   API_KEY     - must match AWS_IOT_LAMBDA_API_KEY in config.php
 */

const API_URL = process.env.API_URL;
const API_KEY = process.env.API_KEY;

export const handler = async (event) => {
    // Extract thing name from topic
    // Topic format: $aws/things/{thingName}/shadow/update/documents
    const topic = event.topic;

    if (!topic) {
        console.error('No topic in event');
        return { statusCode: 400, body: 'No topic' };
    }

    const match = topic.match(/\$aws\/things\/([^/]+)\/shadow\/update\/documents/);

    if (!match) {
        console.error('Could not extract thingName from topic:', topic);
        return { statusCode: 400, body: 'Invalid topic' };
    }

    const thingName = match[1];

    // Extract previous and current reported state
    const previousReported = event.previous?.state?.reported || {};
    const currentReported = event.current?.state?.reported || {};

    // Compute delta
    const changes = diffAssocRecursive(currentReported, previousReported);

    if (Object.keys(changes).length === 0) {
        console.log(`No reported changes for ${thingName}`);
        return { statusCode: 200, body: 'No changes' };
    }

    console.log(`Shadow changes for ${thingName}:`, JSON.stringify(changes));

    // POST to PHP API
    const body = JSON.stringify({
        thing_name: thingName,
        changes: changes,
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
            console.error(`API returned ${response.status}: ${responseText}`);
            throw new Error(`API error ${response.status}`);
        }

        console.log(`API response for ${thingName}: ${responseText}`);
        return { statusCode: 200, body: responseText };
    } catch (error) {
        console.error(`Failed to call API for ${thingName}:`, error.message);
        throw error; // Let Lambda retry
    }
};

/**
 * Recursively compute the diff between two objects.
 * Returns keys from obj1 that differ from obj2.
 */
function diffAssocRecursive(obj1, obj2) {
    const diff = {};

    for (const key of Object.keys(obj1)) {
        const val1 = obj1[key];
        const val2 = obj2[key];

        if (val1 !== null && typeof val1 === 'object' && !Array.isArray(val1)) {
            if (val2 === undefined || val2 === null || typeof val2 !== 'object') {
                diff[key] = val1;
            } else {
                const subDiff = diffAssocRecursive(val1, val2);
                if (Object.keys(subDiff).length > 0) {
                    diff[key] = subDiff;
                }
            }
        } else if (val2 === undefined || !deepEqual(val1, val2)) {
            diff[key] = val1;
        }
    }

    return diff;
}

/**
 * Deep equality check for arrays and primitives.
 */
function deepEqual(a, b) {
    if (a === b) return true;
    if (Array.isArray(a) && Array.isArray(b)) {
        if (a.length !== b.length) return false;
        return a.every((val, i) => deepEqual(val, b[i]));
    }
    if (typeof a === 'object' && typeof b === 'object' && a !== null && b !== null) {
        const keysA = Object.keys(a);
        const keysB = Object.keys(b);
        if (keysA.length !== keysB.length) return false;
        return keysA.every((key) => deepEqual(a[key], b[key]));
    }
    return false;
}
