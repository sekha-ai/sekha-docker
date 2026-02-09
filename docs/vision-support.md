# SEKHA v2.0 Vision Support Guide

**Using Image-Capable LLM Models**

Sekha v2.0 supports vision-capable models that can process both text and images in conversations.

---

## Supported Vision Models

| Model | Provider | Max Images | Max Resolution | Notes |
|-------|----------|------------|----------------|-------|
| **gpt-4o** | OpenAI | 10 per message | 2048x2048 | Best general-purpose vision |
| **gpt-4o-mini** | OpenAI | 10 per message | 2048x2048 | Cost-effective |
| **claude-3.5-sonnet** | Anthropic | 20 per message | 8000x8000 | Excellent for documents |
| **gemini-2.0-flash** | Google | 16 per message | 3072x3072 | Fast, multimodal |
| **moonshot-v1-128k** (Kimi 2.5) | Moonshot AI | 20 per message | 1024x1024 | Chinese + English |
| **llava:13b** | Ollama (local) | 1 per message | Variable | Open-source, privacy-first |

---

## Configuration

### Enable Vision Model

Add `supports_vision: true` to model configuration:

```yaml
# config.yaml
llm_providers:
  - id: openai
    provider_type: openai
    base_url: https://api.openai.com/v1
    api_key: ${OPENAI_API_KEY}
    priority: 1
    models:
      - model_id: gpt-4o
        task: chat_smart
        supports_vision: true
        max_image_size: 20000000  # 20MB
        cost_per_1k_input: 0.0025
        cost_per_1k_output: 0.01

default_models:
  chat_smart: gpt-4o  # Will handle both text and images
```

### Multiple Vision Providers

```yaml
llm_providers:
  # Primary: OpenAI (highest quality)
  - id: openai
    provider_type: openai
    base_url: https://api.openai.com/v1
    api_key: ${OPENAI_API_KEY}
    priority: 1
    models:
      - model_id: gpt-4o
        task: chat_smart
        supports_vision: true

  # Fallback: Ollama (local, free)
  - id: ollama_local
    provider_type: ollama
    base_url: http://ollama:11434
    priority: 2
    models:
      - model_id: llava:13b
        task: chat_vision
        supports_vision: true

default_models:
  chat_smart: gpt-4o
  chat_vision: llava:13b  # Explicit vision task
```

---

## Image Formats

Sekha supports three image input methods:

### 1. Base64 Encoded (Recommended)

**Best for:** Small images, direct API calls

```json
{
  "type": "image_url",
  "image_url": {
    "url": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  }
}
```

### 2. Public URL

**Best for:** Large images, externally hosted

```json
{
  "type": "image_url",
  "image_url": {
    "url": "https://example.com/image.jpg"
  }
}
```

### 3. Local File Path (Proxy only)

**Best for:** Development, testing

```json
{
  "type": "image_url",
  "image_url": {
    "url": "file:///path/to/image.jpg"
  }
}
```

**Supported Formats:** JPG, PNG, GIF, WEBP

---

## Usage Examples

### Via Proxy (OpenAI-Compatible)

**Simple Image Question:**

```bash
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "What is in this image?"
          },
          {
            "type": "image_url",
            "image_url": {
              "url": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
            }
          }
        ]
      }
    ]
  }'
```

**Multiple Images:**

```bash
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "Compare these two images:"},
          {"type": "image_url", "image_url": {"url": "https://example.com/image1.jpg"}},
          {"type": "image_url", "image_url": {"url": "https://example.com/image2.jpg"}}
        ]
      }
    ]
  }'
```

### Via Controller API

**Store Image-Based Conversation:**

```bash
curl -X POST http://localhost:8080/api/v1/conversations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "Analyze this diagram"},
          {"type": "image_url", "image_url": {"url": "data:image/png;base64,..."}}
        ]
      }
    ],
    "metadata": {
      "has_images": true,
      "image_count": 1
    }
  }'
```

### Python SDK Example

```python
import base64
import requests

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

# Encode image
base64_image = encode_image("screenshot.png")

# Send to Sekha
response = requests.post(
    "http://localhost:8081/v1/chat/completions",
    json={
        "model": "gpt-4o",
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "What error is shown in this screenshot?"},
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{base64_image}"}}
                ]
            }
        ]
    },
    headers={"Authorization": "Bearer YOUR_API_KEY"}
)

print(response.json()["choices"][0]["message"]["content"])
```

### TypeScript Example

```typescript
import fs from 'fs';
import axios from 'axios';

const imageBuffer = fs.readFileSync('diagram.jpg');
const base64Image = imageBuffer.toString('base64');

const response = await axios.post('http://localhost:8081/v1/chat/completions', {
  model: 'gpt-4o',
  messages: [
    {
      role: 'user',
      content: [
        { type: 'text', text: 'Explain this architecture diagram' },
        { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Image}` } }
      ]
    }
  ]
}, {
  headers: { 'Authorization': 'Bearer YOUR_API_KEY' }
});

console.log(response.data.choices[0].message.content);
```

---

## Use Cases

### 1. Screenshot Analysis

**Ask about UI/UX, bugs, error messages**

```bash
curl -X POST http://localhost:8081/v1/chat/completions \
  -d '{
    "model": "gpt-4o",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "What UI improvements would you suggest?"},
        {"type": "image_url", "image_url": {"url": "file:///screenshots/app.png"}}
      ]
    }]
  }'
```

### 2. Document OCR & Extraction

**Extract text, tables, structured data from images**

```bash
curl -X POST http://localhost:8081/v1/chat/completions \
  -d '{
    "model": "gpt-4o",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "Extract all data from this invoice as JSON"},
        {"type": "image_url", "image_url": {"url": "https://example.com/invoice.jpg"}}
      ]
    }]
  }'
```

### 3. Diagram Understanding

**Explain flowcharts, architecture diagrams, ERDs**

```bash
curl -X POST http://localhost:8081/v1/chat/completions \
  -d '{
    "model": "claude-3.5-sonnet",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "Explain this database schema"},
        {"type": "image_url", "image_url": {"url": "data:image/png;base64,..."}}
      ]
    }]
  }'
```

### 4. Multi-Image Comparison

**Before/after, A/B testing, debugging**

```bash
curl -X POST http://localhost:8081/v1/chat/completions \
  -d '{
    "model": "gpt-4o",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "What changed between these versions?"},
        {"type": "image_url", "image_url": {"url": "https://example.com/before.png"}},
        {"type": "image_url", "image_url": {"url": "https://example.com/after.png"}}
      ]
    }]
  }'
```

---

## Best Practices

### Image Optimization

**1. Resize Large Images**

```python
from PIL import Image

img = Image.open("large_image.jpg")
img.thumbnail((2048, 2048))
img.save("optimized.jpg", quality=85)
```

**2. Use JPEG for Photos, PNG for Screenshots**

```python
# Screenshot (sharp text)
image.save("screenshot.png", format="PNG")

# Photo (gradients)
image.save("photo.jpg", format="JPEG", quality=90)
```

**3. Prefer Base64 for Small Images (<5MB)**

```python
if file_size < 5 * 1024 * 1024:
    use_base64()
else:
    upload_to_cdn()  # Return public URL
```

### Cost Optimization

**Vision models are more expensive:**
- gpt-4o with images: ~$0.0025/1k input tokens + image cost
- gpt-4o-mini with images: ~$0.00015/1k input tokens + image cost
- Image cost: ~$0.0008 per 1024x1024 image

**Tips:**
1. Use `gpt-4o-mini` for simple image tasks
2. Resize images to minimum required resolution
3. Cache image analysis results in Sekha memory

### Security

**1. Sanitize Image URLs**

```python
import re

def is_safe_url(url):
    if url.startswith("data:"):
        return True  # Base64
    if re.match(r"https?://", url):
        return "localhost" not in url  # Block internal requests
    return False
```

**2. Limit Image Sizes**

```yaml
# config.yaml
models:
  - model_id: gpt-4o
    max_image_size: 20000000  # 20MB limit
    max_images_per_request: 5
```

**3. Content Filtering**

Enable if provider supports:

```python
response = requests.post(
    "http://localhost:8081/v1/chat/completions",
    json={
        "model": "gpt-4o",
        "messages": [...],
        "moderation": True  # Enable content filtering
    }
)
```

---

## Troubleshooting

### Issue: "Model does not support vision"

**Cause:** Model not configured with `supports_vision: true`

**Solution:**
```yaml
models:
  - model_id: gpt-4o
    supports_vision: true  # Add this
```

### Issue: Image not loading (HTTP 403)

**Cause:** Private URL or authentication required

**Solution:** Use base64 encoding instead:
```python
base64_image = base64.b64encode(image_bytes).decode()
url = f"data:image/jpeg;base64,{base64_image}"
```

### Issue: "Image too large" error

**Cause:** Exceeds provider limits

**Solution:** Resize before sending:
```python
from PIL import Image

img = Image.open("large.jpg")
img.thumbnail((2048, 2048))
img.save("resized.jpg")
```

### Issue: Poor image understanding

**Causes:**
1. Low resolution
2. Compression artifacts
3. Model not suited for task

**Solutions:**
1. Use higher quality source images
2. Try different model (e.g., Claude for documents)
3. Add more descriptive text prompts

### Issue: High costs

**Solution:** Add cost limits:
```yaml
routing:
  cost_limit_per_request: 0.01
  prefer_free_providers: false
```

---

## Advanced: Local Vision Models (Ollama)

**Install LLaVA:**

```bash
# Pull vision model
ollama pull llava:13b

# Test locally
ollama run llava:13b "What is in this image?" --image screenshot.png
```

**Configure in Sekha:**

```yaml
llm_providers:
  - id: ollama_local
    provider_type: ollama
    base_url: http://ollama:11434
    priority: 1
    models:
      - model_id: llava:13b
        task: chat_vision
        supports_vision: true
        context_window: 4096

default_models:
  chat_vision: llava:13b  # Free, private, local
```

**Benefits:**
- ✅ Completely private (no data leaves your machine)
- ✅ No API costs
- ✅ Unlimited requests

**Limitations:**
- ⚠️ Lower accuracy than GPT-4o/Claude
- ⚠️ Slower inference
- ⚠️ Single image per request only

---

## Examples Repository

More vision examples:
https://github.com/sekha-ai/sekha-docker/tree/main/examples/vision

- `screenshot-analysis.py`
- `invoice-extraction.py`
- `diagram-explainer.py`
- `multi-image-comparison.py`

---

**Next:** [Configuration Guide](configuration-v2.md) | [Migration Guide](migration-guide-v2.md)
