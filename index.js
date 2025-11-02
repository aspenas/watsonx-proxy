// Load environment variables from .env file in development
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config();
}

const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();

// Environment configuration with defaults
const config = {
    apiKey: process.env.WATSONX_API_KEY,
    instanceId: process.env.WATSONX_INSTANCE_ID || '20251101-2338-1901-402d-f441a2b6b26b',
    port: process.env.PORT || 3000,
    nodeEnv: process.env.NODE_ENV || 'development',
    corsOrigins: process.env.CORS_ORIGINS ? process.env.CORS_ORIGINS.split(',') : '*',
    rateLimitWindow: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
    rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    logLevel: process.env.LOG_LEVEL || 'info',
    tokenRefreshBuffer: parseInt(process.env.TOKEN_REFRESH_BUFFER) || 300,
    requestTimeout: parseInt(process.env.REQUEST_TIMEOUT) || 30000,
    healthCheckInterval: parseInt(process.env.HEALTH_CHECK_INTERVAL) || 60000
};

// Check for required environment variables
if (!config.apiKey) {
    console.error('❌ ERROR: WATSONX_API_KEY environment variable is required');
    console.error('Please set it in Railway dashboard or local .env file');
    process.exit(1);
}

// API URLs
const IAM_TOKEN_URL = 'https://iam.platform.saas.ibm.com/siusermgr/api/1.0/apikeys/token';
const BASE_URL = 'https://api.dl.watson-orchestrate.ibm.com';

// CORS configuration
const corsOptions = {
    origin: config.corsOrigins,
    credentials: true,
    optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        if (config.logLevel === 'info' || config.logLevel === 'debug') {
            console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
        }
    });
    next();
});

// Simple in-memory rate limiting
const requestCounts = new Map();
const rateLimitMiddleware = (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const now = Date.now();

    if (!requestCounts.has(ip)) {
        requestCounts.set(ip, { count: 1, windowStart: now });
        return next();
    }

    const record = requestCounts.get(ip);

    if (now - record.windowStart > config.rateLimitWindow) {
        record.count = 1;
        record.windowStart = now;
        return next();
    }

    if (record.count >= config.rateLimitMax) {
        return res.status(429).json({
            error: 'Too Many Requests',
            message: `Rate limit exceeded. Please try again later.`,
            retryAfter: Math.ceil((record.windowStart + config.rateLimitWindow - now) / 1000)
        });
    }

    record.count++;
    next();
};

app.use(rateLimitMiddleware);

// Token management with retry logic
let tokenCache = {
    token: null,
    expiry: null,
    refreshPromise: null
};

async function getToken(retryCount = 0) {
    const maxRetries = 3;

    // Check if token is still valid
    if (tokenCache.token && tokenCache.expiry && new Date() < tokenCache.expiry) {
        return tokenCache.token;
    }

    // If a refresh is already in progress, wait for it
    if (tokenCache.refreshPromise) {
        return tokenCache.refreshPromise;
    }

    // Start new token refresh
    tokenCache.refreshPromise = (async () => {
        try {
            console.log('🔄 Fetching new JWT token from Watsonx...');

            const response = await axios.post(
                IAM_TOKEN_URL,
                { apikey: config.apiKey },
                {
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    timeout: 10000
                }
            );

            tokenCache.token = response.data.token;
            // Refresh token before it expires (subtract buffer time)
            const expiresIn = response.data.expires_in || 7200;
            tokenCache.expiry = new Date(Date.now() + (expiresIn - config.tokenRefreshBuffer) * 1000);
            tokenCache.refreshPromise = null;

            console.log(`✅ New token obtained, expires at: ${tokenCache.expiry}`);
            return tokenCache.token;

        } catch (error) {
            tokenCache.refreshPromise = null;

            if (retryCount < maxRetries) {
                const delay = Math.pow(2, retryCount) * 1000; // Exponential backoff
                console.log(`⚠️ Token fetch failed, retrying in ${delay}ms...`);
                await new Promise(resolve => setTimeout(resolve, delay));
                return getToken(retryCount + 1);
            }

            console.error('❌ Failed to get JWT token after retries:', error.message);
            throw error;
        }
    })();

    return tokenCache.refreshPromise;
}

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        const token = await getToken();
        res.json({
            status: 'healthy',
            message: 'Watsonx proxy is running and authenticated',
            tokenValid: !!token,
            tokenExpiry: tokenCache.expiry,
            instance: config.instanceId,
            uptime: process.uptime(),
            memory: process.memoryUsage()
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

// Service info endpoint
app.get('/', (req, res) => {
    res.json({
        service: 'Watsonx Orchestrate Proxy',
        version: '1.2.0',
        status: 'running',
        endpoints: {
            health: '/health',
            orchestrate: {
                agents: '/v1/orchestrate/agents',
                skills: '/v1/orchestrate/skills',
                threads: '/v1/orchestrate/threads'
            },
            api: '/* (proxies all requests to Watsonx)'
        },
        instance: config.instanceId,
        tokenCached: !!tokenCache.token,
        tokenExpiry: tokenCache.expiry,
        environment: config.nodeEnv
    });
});

// Proxy all other requests to Watsonx with retry logic
app.all('*', async (req, res) => {
    const maxRetries = 2;
    let lastError;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            // Get fresh token
            const token = await getToken();

            // Build target URL - add instance ID if not present for orchestrate endpoints
            let targetPath = req.path;
            if (req.path.includes('/v1/orchestrate') && !req.path.includes('/instances/')) {
                // Add instance ID to path for orchestrate endpoints
                targetPath = `/instances/${config.instanceId}${req.path}`;
            }
            const targetUrl = `${BASE_URL}${targetPath}`;

            if (config.logLevel === 'debug') {
                console.log(`📡 Proxying ${req.method} ${req.path} -> ${targetUrl}`);
            }

            // Prepare headers
            const headers = {
                ...req.headers,
                'Authorization': `Bearer ${token}`,
                'Content-Type': req.headers['content-type'] || 'application/json',
                'Accept': req.headers['accept'] || 'application/json',
                // Remove headers that shouldn't be forwarded
                'host': undefined,
                'connection': undefined,
                'content-length': undefined
            };

            // Clean up undefined headers
            Object.keys(headers).forEach(key =>
                headers[key] === undefined && delete headers[key]
            );

            // Forward request to Watsonx
            const response = await axios({
                method: req.method,
                url: targetUrl,
                headers,
                data: req.body,
                params: req.query,
                timeout: config.requestTimeout,
                validateStatus: () => true, // Don't throw on any status
                maxRedirects: 5
            });

            // Log response status
            if (config.logLevel === 'debug') {
                console.log(`✅ Response: ${response.status} ${response.statusText}`);
            }

            // Forward response headers
            const responseHeaders = ['content-type', 'x-request-id', 'x-correlation-id', 'cache-control'];
            responseHeaders.forEach(header => {
                if (response.headers[header]) {
                    res.setHeader(header, response.headers[header]);
                }
            });

            // Return response
            return res.status(response.status).json(response.data);

        } catch (error) {
            lastError = error;

            if (attempt < maxRetries) {
                const delay = Math.pow(2, attempt) * 500; // Exponential backoff
                console.log(`⚠️ Request failed (attempt ${attempt + 1}), retrying in ${delay}ms...`);
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    }

    // All retries failed
    console.error('❌ Proxy request failed after retries:', lastError.message);

    // Handle different error types
    if (lastError.code === 'ECONNABORTED' || lastError.code === 'ETIMEDOUT') {
        return res.status(504).json({
            error: 'Gateway Timeout',
            message: 'Request to Watsonx timed out',
            details: lastError.message
        });
    }

    if (lastError.response) {
        // Forward Watsonx error response
        return res.status(lastError.response.status).json(lastError.response.data);
    }

    // Generic error
    res.status(500).json({
        error: 'Proxy Error',
        message: 'Failed to proxy request to Watsonx',
        details: lastError.message
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        error: 'Internal Server Error',
        message: 'An unexpected error occurred',
        details: config.nodeEnv === 'development' ? err.message : undefined
    });
});

// Periodic health check
if (config.healthCheckInterval > 0) {
    setInterval(async () => {
        try {
            await getToken();
            if (config.logLevel === 'debug') {
                console.log('🩺 Health check passed');
            }
        } catch (error) {
            console.error('🩺 Health check failed:', error.message);
        }
    }, config.healthCheckInterval);
}

// Start server
const server = app.listen(config.port, () => {
    console.log('');
    console.log('========================================');
    console.log('🚀 Watsonx Orchestrate Proxy v1.2.0');
    console.log('========================================');
    console.log(`✅ Server running on port ${config.port}`);
    console.log(`📍 Instance ID: ${config.instanceId}`);
    console.log(`🔐 API Key: ${config.apiKey.substring(0, 20)}...`);
    console.log(`🌍 Environment: ${config.nodeEnv}`);
    console.log(`🔒 CORS: ${config.corsOrigins}`);
    console.log(`⏱️ Rate Limit: ${config.rateLimitMax} requests per ${config.rateLimitWindow}ms`);
    console.log('');
    console.log('Endpoints:');
    console.log(`  Health Check: http://localhost:${config.port}/health`);
    console.log(`  Service Info: http://localhost:${config.port}/`);
    console.log(`  Agents: http://localhost:${config.port}/v1/orchestrate/agents`);
    console.log(`  API Proxy: http://localhost:${config.port}/*`);
    console.log('========================================');
    console.log('');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('\nSIGINT received, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});

module.exports = app;