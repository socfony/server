import Ajv from 'ajv';

export const ajv = new Ajv()

// create a ID format
.addFormat("id", data => /^[a-zA-Z0-9_-]{64}$/.test(data))

// Create a E-Mail format
.addFormat("email", data => /^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/i.test(data))
