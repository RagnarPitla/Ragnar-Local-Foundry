"""
Native Azure AI Foundry Local SDK chat sample for Python.

Run from this folder with:
    pip install -r requirements.txt
    python3 chat.py <alias> "<prompt>"

Example:
    python3 chat.py qwen2.5-0.5b "What can I build with Foundry Local?"
"""

import sys

DEFAULT_MODEL = "qwen2.5-0.5b"
DEFAULT_PROMPT = "What is a friendly way to explain Azure AI Foundry Local on a Mac?"


def print_progress(label):
    def _callback(progress):
        try:
            percent = max(0, min(100, round(float(progress))))
        except (TypeError, ValueError):
            percent = 0
        print(f"\r{label}: {percent}%", end="", flush=True)
        if percent >= 100:
            print()

    return _callback


def is_service_error(error):
    text = str(error).lower()
    return any(term in text for term in ["connection", "connect", "service", "endpoint", "socket", "refused"])


def print_friendly_error(error):
    print("\nThe Foundry Local Python chat sample could not finish.", file=sys.stderr)

    if isinstance(error, ModuleNotFoundError):
        print("Run pip install -r requirements.txt in examples/python, then try again.", file=sys.stderr)
    elif is_service_error(error):
        print("Foundry Local may not be installed or running.", file=sys.stderr)
        print("Run ../../scripts/install-mac.sh or foundry service restart, then try again.", file=sys.stderr)
    else:
        print(str(error), file=sys.stderr)


def choice_content(response):
    choices = getattr(response, "choices", []) or []
    if not choices:
        return "(no content returned)"
    message = getattr(choices[0], "message", None)
    return getattr(message, "content", None) or "(no content returned)"


def delta_content(chunk):
    choices = getattr(chunk, "choices", []) or []
    if not choices:
        return ""
    delta = getattr(choices[0], "delta", None)
    return getattr(delta, "content", None) or ""


def run():
    model_alias = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_MODEL
    prompt = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_PROMPT
    model = None

    from foundry_local_sdk import Configuration, FoundryLocalManager

    config = Configuration(app_name="ragnar-local-foundry")
    FoundryLocalManager.initialize(config)
    manager = FoundryLocalManager.instance

    try:
        model = manager.catalog.get_model(model_alias)
        model.download(print_progress(f"Downloading {model_alias}"))
        print(f"Loading {model_alias}...")
        model.load()

        client = model.get_chat_client()
        messages = [{"role": "user", "content": prompt}]

        print("\nNon-streaming response:")
        response = client.complete_chat(messages)
        print(choice_content(response))

        print("\nStreaming response:")
        for chunk in client.complete_streaming_chat(messages):
            token = delta_content(chunk)
            if token:
                print(token, end="", flush=True)
        print()
    finally:
        if model is not None:
            print("\nUnloading model...")
            model.unload()


if __name__ == "__main__":
    try:
        run()
    except Exception as exc:
        print_friendly_error(exc)
        sys.exit(1)
