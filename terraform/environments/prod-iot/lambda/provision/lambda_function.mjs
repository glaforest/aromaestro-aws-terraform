export const handler = async (event) => {
  console.log('Received:', JSON.stringify(event));

  const thingName = event.thingName;
  if (!thingName) {
    console.error('ERROR: No thingName in event');
    return {
      statusCode: 400,
      body: 'Missing thingName',
    };
  }

  // Gestion du timestamp
  let provisionedAt;
  if (event.provisioned_at) {
    provisionedAt = new Date(event.provisioned_at);
  } else {
    provisionedAt = new Date();
  }

  try {
    const response = await fetch(process.env.API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': process.env.API_KEY,
      },
      body: JSON.stringify({
        thing_name: thingName,
        provisioned_at: provisionedAt.toISOString(),
        status: 'provisioned',
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      console.error(`API error ${response.status}: ${body}`);
      throw new Error(`API returned ${response.status}`);
    }

    console.log(`SUCCESS: Device ${thingName} registered`);

    return {
      statusCode: 200,
      body: `Device ${thingName} registered`,
    };

  } catch (error) {
    console.error('ERROR:', error.message);
    throw error;
  }
};