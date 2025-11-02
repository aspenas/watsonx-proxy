const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();

// Enable CORS for all origins
app.use(cors());
app.use(express.json());

// Configuration from environment variables (Railway will set these)
const API_KEY = process.env.WATSONX_API_KEY || 'azE6dXNyX2FjMTUwODM4LWZkNWItM2M0Zi05NzU3LTA2YTBkNmVjMDkwNTpUMHg4akRlRG9xc2Nqb2R2YVR0SHdtYkVZaE9LU05jYTlzMTZhdFVnZkZnPTpkK1VY';
const INSTANCE_ID = process.env.WATSONX_INSTANCE_ID || '20251101-2338-1901-402d-f441a2b6b26b';
const BASE_URL = `https://api.dl.watson-orchestrate.ibm.com/instances/${INSTANCE_ID}`;

// Token management
let tokenCache = {
    token: null,
    expiry: null
};

async function getToken() {
    // Return cached token if still valid
    if (tokenCache.token && tokenCache.expiry && new Date() < tokenCache.expiry) {
        console.log('Using cached token, expires at:', tokenCache.expiry);
        return tokenCache.token;
    }

    console.log('Fetching new JWT token from Watsonx...');
    try {
        const response = await axios.post(
            'https://iam.platform.saas.ibm.com/siusermgr/api/1.0/apikeys/token',
            { apikey: API_KEY },
            {
                headers: { 'Content-Type': 'application/json' },
                timeout: 10000 // 10 second timeout
            }
        );

        if (!response.data || !response.data.token) {
            throw new Error('Invalid response from token endpoint');
        }

        tokenCache.token = response.data.token;
        // Refresh 5 minutes before expiry for safety
        const expiresIn = response.data.expires_in || 7200;
        tokenCache.expiry = new Date(Date.now() + (expiresIn - 300) * 1000);

        console.log(`✅ New token obtained, expires at: ${tokenCache.expiry}`);
        return tokenCache.token;
    } catch (error) {
        console.error('❌ Failed to get token:', error.message);
        if (error.response) {
            console.error('Response:', error.response.data);
        }
        throw error;
    }
}

// Health check endpoint
app.get('/', (req, res) => {
    res.json({
        service: 'Watsonx Orchestrate Proxy',
        status: 'running',
        endpoints: {
            health: '/health',
            api: '/* (proxies to Watsonx)'
        },
        instance: INSTANCE_ID,
        tokenCached: !!(tokenCache.token && tokenCache.expiry && new Date() < tokenCache.expiry),
        tokenExpiry: tokenCache.expiry || null
    });
});

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        // Try to get/refresh token
        await getToken();
        res.json({
            status: 'healthy',
            message: 'Watsonx proxy is running and authenticated',
            tokenValid: true,
            tokenExpiry: tokenCache.expiry,
            instance: INSTANCE_ID
        });
    } catch (error) {
        res.status(503).json({
            status: 'unhealthy',
            message: 'Failed to authenticate with Watsonx',
            error: error.message,
            tokenValid: false
        });
    }
});

// Proxy all other requests to Watsonx
app.all('*', async (req, res) => {
    try {
        // Get fresh token
        const token = await getToken();

        // Build target URL
        const targetUrl = `${BASE_URL}${req.path}`;

        console.log(`📡 Proxying ${req.method} ${req.path} -> ${targetUrl}`);

        // Forward request to Watsonx
        const response = await axios({
            method: req.method,
            url: targetUrl,
            headers: {
                ...req.headers,
                'Authorization': `Bearer ${token}`,
                'Content-Type': req.headers['content-type'] || 'application/json',
                // Remove headers that shouldn't be forwarded
                'Host': undefined,
                'host': undefined,
                'connection': undefined,
                'content-length': undefined
            },
            data: req.body,
            params: req.query,
            validateStatus: () => true, // Don't throw on any status code
            timeout: 30000 // 30 second timeout
        });

        // Log response status
        console.log(`✅ Response: ${response.status} ${response.statusText}`);

        // Forward response back to client
        res.status(response.status);

        // Forward relevant headers
        const headersToForward = ['content-type', 'x-request-id', 'x-correlation-id'];
        headersToForward.forEach(header => {
            if (response.headers[header]) {
                res.setHeader(header, response.headers[header]);
            }
        });

        res.send(response.data);

    } catch (error) {
        console.error('❌ Proxy error:', error.message);

        // Handle different error types
        if (error.code === 'ECONNABORTED') {
            res.status(504).json({
                error: 'Gateway Timeout',
                message: 'Request to Watsonx timed out',
                details: error.message
            });
        } else if (error.response) {
            // Forward error from Watsonx
            res.status(error.response.status).json(error.response.data);
        } else {
            // Generic error
            res.status(500).json({
                error: 'Proxy Error',
                message: error.message,
                path: req.path,
                method: req.method
            });
        }
    }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('========================================');
    console.log('🚀 Watsonx Orchestrate Proxy Started');
    console.log('========================================');
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`📍 Instance ID: ${INSTANCE_ID}`);
    console.log(`🔐 API Key: ${API_KEY.substring(0, 20)}...`);
    console.log('');
    console.log('Endpoints:');
    console.log(`  Health Check: http://localhost:${PORT}/health`);
    console.log(`  API Proxy: http://localhost:${PORT}/*`);
    console.log('========================================');
});