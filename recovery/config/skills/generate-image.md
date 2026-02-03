# generate-image

Generate images using OpenAI's DALL-E API.

## Usage

`/generate-image <prompt>`

## Description

Uses DALL-E 3 to generate an image based on the provided prompt. The image is saved to the current working directory or a specified location.

## Instructions

When invoked, generate an image using the OpenAI API:

1. Parse the prompt from the user's request
2. Call DALL-E 3 API to generate the image
3. Download and save the image locally
4. Display the path to the generated image

Use this Python script to generate images:

```python
import openai
import os
import requests
from datetime import datetime

def generate_image(prompt: str, output_dir: str = ".") -> str:
    """Generate an image using DALL-E 3."""
    client = openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

    response = client.images.generate(
        model="dall-e-3",
        prompt=prompt,
        size="1792x1024",  # Wide format for banners
        quality="standard",
        n=1,
    )

    image_url = response.data[0].url

    # Download the image
    img_response = requests.get(image_url)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"generated_{timestamp}.png"
    filepath = os.path.join(output_dir, filename)

    with open(filepath, "wb") as f:
        f.write(img_response.content)

    return filepath
```

Run the script with the user's prompt and report the saved file path.

## Examples

- `/generate-image A futuristic cityscape at sunset`
- `/generate-image Abstract representation of artificial intelligence`
- `/generate-image Banner for article about neural networks, digital art style`
