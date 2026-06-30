

- Production-grade `OnRejected` returning RFC 9457 ProblemDetails + `Retry-After` header
- Multi-tenant tier resolution (Free / Pro / Enterprise) partitioned by `X-API-Key`
- Optional Redis backplane for multi-instance enforcement (off by default)
- `[DisableRateLimiting]` for health endpoints

## Run it locally

```bash
cd RateLimiting.Api
dotnet run
```
Open Scalar at `https://localhost:5000/scalar/v1` to explore the endpoints.

## Run it on docker (if setup is done)
```bash
cd rate-limiting-aspnet-core
docker compose up --build
```
Open Scalar at `https://localhost:8080/scalar/v1` to explore the endpoints.



## Try the rate limiter

The Free-tier API key is in `appsettings.json` as `free-key-001` (60 tokens/min):

```bash
# This will be rate-limited around the 60th call inside a minute
for i in {1..70}; do
  curl -i -H "X-API-Key: free-key-001" https://localhost:5xxx/api/pricing
done
```

The 61st response is:

```
HTTP/2 429
content-type: application/problem+json
retry-after: 58

{
  "type": "https://datatracker.ietf.org/doc/html/rfc6585#section-4",
  "title": "Too many requests",
  "status": 429,
  "detail": "...",
  "instance": "/api/pricing",
  "traceId": "..."
}
```

## More testing commands you can change the free-key-001 to pro-key-02 to increase rate limit
```
for i in {1..70}; do
  curl -i -H "X-API-Key: free-key-001" http://localhost:5000/api/login \
  --request POST \
  --header 'Content-Type: application/json' \
  --data '{
  "email": "",
  "password": ""
}'
done
```
```
for i in {1..70}; do
  curl -i -H "X-API-Key: free-key-001" http://localhost:5000/api/pricing
done
```
```
for i in {1..70}; do
  curl -i -H "X-API-Key: free-key-001" curl http://localhost:5000/health
done
```
```
for i in {1..70}; do
  curl -i -H "X-API-Key: free-key-001" curl http://localhost:5000/api/internal/health
done
```



## Endpoints

| Endpoint | Policy | Algorithm | Use case |
|----------|--------|-----------|----------|
| `GET /api/pricing` | `public-api` | Token Bucket | Public API default |
| `GET /api/internal/health` | `internal-rpc` | Fixed Window | Trusted internal RPC |
| `POST /api/login` | `auth-endpoints` | Sliding Window | Security-sensitive auth |
| `POST /api/upload` | `file-upload` | Concurrency | In-flight cap on expensive work |
| `GET /health` | (disabled) | - | Always allowed |

## Multi-tenant tiers

The global limiter resolves the API key on every request and partitions accordingly:

| Tier | Token Limit | Refill | API key (demo) |
|------|------------|--------|----------------|
| Anonymous (no key) | 20 / min | Fixed Window | (none) |
| Invalid key | 5 / min | Fixed Window | any unknown value |
| Free | 60 / min | Token Bucket | `free-key-001` |
| Pro | 600 / min | Token Bucket | `pro-key-002` |
| Enterprise | 6000 / min | Token Bucket | `enterprise-key-003` |
