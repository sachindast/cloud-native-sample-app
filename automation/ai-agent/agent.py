import requests
import json
import sys


# --------------------------------------------------
# Add Cloud-Native DevOps project to Python path
# --------------------------------------------------

sys.path.append("/home/sachin/cloud-native-sample-app")


# --------------------------------------------------
# Import existing Platform Automation function
# --------------------------------------------------

from automation.platform.platform import get_kubernetes_nodes


OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
MODEL = "llama3.2:3b"


# --------------------------------------------------
# Tool definition
# --------------------------------------------------

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_kubernetes_nodes",
            "description": (
                "Returns the current Kubernetes node health "
                "including node names, statuses and overall health."
            ),
            "parameters": {
                "type": "object",
                "properties": {},
                "required": []
            }
        }
    }
]


# --------------------------------------------------
# User request
# --------------------------------------------------

messages = [
    {
        "role": "user",
        "content": "Are my Kubernetes nodes healthy?"
    }
]


# --------------------------------------------------
# First LLM call
# --------------------------------------------------

response = requests.post(
    OLLAMA_URL,
    json={
        "model": MODEL,
        "messages": messages,
        "tools": tools,
        "stream": False
    }
)

response.raise_for_status()

data = response.json()

assistant_message = data["message"]

print("\nLLM response:")
print(json.dumps(assistant_message, indent=2))


# --------------------------------------------------
# Process tool calls
# --------------------------------------------------

tool_calls = assistant_message.get("tool_calls", [])

if tool_calls:

    for tool_call in tool_calls:

        tool_name = tool_call["function"]["name"]

        print(f"\nTool requested: {tool_name}")

        if tool_name == "get_kubernetes_nodes":

            # --------------------------------------
            # Execute REAL platform automation
            # --------------------------------------

            result = get_kubernetes_nodes()

            print("\nTool result:")
            print(json.dumps(result, indent=2))

            # --------------------------------------
            # Add assistant tool request
            # --------------------------------------

            messages.append(assistant_message)

            # --------------------------------------
            # Add tool result
            # --------------------------------------

            messages.append(
                {
                    "role": "tool",
                    "content": json.dumps(result)
                }
            )


# --------------------------------------------------
# Second LLM call
# --------------------------------------------------

response = requests.post(
    OLLAMA_URL,
    json={
        "model": MODEL,
        "messages": messages,
        "tools": tools,
        "stream": False
    }
)

response.raise_for_status()

data = response.json()


# --------------------------------------------------
# Final response
# --------------------------------------------------

final_answer = data["message"]["content"]

print("\nFinal answer:")
print(final_answer)