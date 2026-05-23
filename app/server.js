const express = require('express');

const app = express();

const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || "1.0.0";
const APP_ENV = process.env.APP_ENV || "development";

app.get('/', (req, res) => {
    res.send('Cloud-Native DevOps Platform on AWS');
});

app.get('/health', (req, res) => {
    res.json({
        status: 'UP'
    });
});

app.get('/version', (req, res) => {
    res.json({
        version: APP_VERSION,
        environment: APP_ENV
    });
});

app.listen(PORT, () => {
    console.log(`Application running on port ${PORT}`);
});
