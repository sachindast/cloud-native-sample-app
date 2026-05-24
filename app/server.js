const express = require('express');

const app = express();

const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || "2.0.0";
const APP_ENV = process.env.APP_ENV || "development";

app.get('/', (req, res) => {
    res.send('Project: Cloud-Native DevOps Platform on AWS');
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

app.get('/config', (req, res) => {
    res.json({
        environment: process.env.APP_ENV,
        version: process.env.APP_VERSION,
        message: process.env.APP_MESSAGE,
        secretConfigured: process.env.APP_SECRET ? true : false
    });
});
