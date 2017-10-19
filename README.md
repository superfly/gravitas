# Gravitas 
## The serious, sophisticated globally recognized avatar

This is a thin proxy that runs in front of Gravatar, and lets you use the service without leaking (a) your users' emails/identities and (b) a whole bunch of traffic information to Gravatar-the-service.

### Leaking users' info?

Yes. Gravatar is leaky, you give up user email addresses, let peoples' content be linked across sites, and send a tremendous amount of information to Gravatar with each request. It's not great, but the service is convenient.


### What Gravitas solves

*  Much more difficult to identify the same user across sites
*  Masks users' personal data so Gravatar can't see it, including:
    * IP address
    * Browser information (and all other request headers)
    * Referrer
    * Total number of requests (when run behind a caching proxy)

### How to Use

#### Use it with fly.io

We built a global proxy for developers, it works seamlessly with Gravitas. You can set it up here with a few clicks: https://fly.io

#### Run it standalone

First, generate a base64 encoded 32 byte encryption key:

```
irb> key = SecureRandom.urlsafe_base64(32)
```

Set the key as an environment variable named `GRAVITAS_KEY`.

Run the app with Ruby, `ruby app.rb` (this uses port 4567 by default)

Generate encrypted Gravatar parameters.
```
curl -X POST -d '' -H 'Authorization: <key>' http://localhost:4567/avatar/767fc9c115a1b989744c755db47feb60?s=132
```

### Caveats

* We don't obfuscate users' actual the images we return. If a user has a unique gravatar, you can still find all the places they use it with a reverse image search.
* This hides a lot from the backend gravatar servers, but they can still determine that requests are happening for a given email.
* Getting the encrypted parameter from a webservice is relatively expensive. You should probably store a fully "avatar url" in your own database, rather than trying to use the `POST` API in realtime.