from twisted.web.server import Request
from synapse.http.server import respond_with_json


async def handle_request(self, request: Request) -> None:
    respond_with_json(
        request,
        200,
        {
            "fi.mau.bridges": [
                "https://matrix-discord.taila659a.ts.net",
                "https://matrix-googlechat.taila659a.ts.net",
                "https://matrix-slack.taila659a.ts.net",
            ]
        },
    )
