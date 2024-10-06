# Fake LLM

```bash
cp config.example.yml config.yml
# edit config

# start server on port 12345
ruby server.rb

# start server with port
ruby server.rb -p 1234
```

# Test

```bash
curl -X POST http://localhost:12345/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "fake_llm",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```
