export const handler = async (event) => {                                                                                                                                                      
  console.log('Received:', JSON.stringify(event));      

  const response = await fetch(
      process.env.API_URL,
      {                                                                                                                                                                                      
          method: 'POST',
          headers: {                                                                                                                                                                         
              'Content-Type': 'application/json',       
              'X-Api-Key': process.env.API_KEY,
          },                                                                                                                                                                                 
          body: JSON.stringify({
              serial:     event.serial,                                                                                                                                                      
              request_id: event.request_id,             
              command:    event.command,
              status:     event.status,
              message:    event.message,
          }),                                                                                                                                                                                
      }
  );                                                                                                                                                                                         
                                                        
  if (!response.ok) {
      const body = await response.text();
      console.error(`API error ${response.status}: ${body}`);
      throw new Error(`API returned ${response.status}`);                                                                                                                                    
  }
                                                                                                                                                                                             
  return { statusCode: 200 };                           
};