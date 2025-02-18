# nadeko.net Invidious fork

This is a fork of Invidious with features that I have done for my own instance. If you want to maintain an instance, feel free to use this fork and it's container images (they are also compatible with Podman, not just docker!)

https://git.nadeko.net/Fijxu/-/packages/container/invidious/latest

> [!CAUTION]
> If you already have an Invidious instance running the upstream code, moving it to this fork will not work for you!
> This is due to the "Removal of materialized views on PostgreSQL" pull request that requires a migration of the database
> using it.
>
> If you don't have an instance already, you can use this fork safely, but you will not be able to switch to upstream Invidious.

## Features and changes of this fork:

- [Use a Redis compatible DB for video cache instead of just PostgreSQL](https://git.nadeko.net/Fijxu/invidious/commit/bbc5913b8dacaed4d466bcc466a0782d5e3f5edc): Invidious by default caches the video information for some hours in PostgreSQL. Since the data is accessed a lot, it is better off using an in memory database instead, it's faster and it will not wear out your SSD (due to constant writes to the database).

It can be set using this on `config.yml`:
```yaml
redis_url: tcp://127.0.0.1:6379
```

- [Removal of materialized views on PostgreSQL](github.com/iv-org/invidious/pull/2469): If you don't have this on your Invidious public instance, your SSD will suffer and it will catch on fire https://github.com/iv-org/invidious/pull/2469#issuecomment-2012623454

- External video playback proxy: Let's you use an external video playback proxy like https://git.nadeko.net/Fijxu/http3-ytproxy or https://github.com/TeamPiped/piped-proxy instead of the one that is bundled with Invidious. It's useful if you are proxying video and your throughput is not low. I did this to distribute the traffic across different servers. If you are selfhosting only for a few amount of people, this is not really useful for you.

It can be set using this on `config.yml`:
```yaml
external_videoplayback_proxy: "https://inv-proxy.example.com"
```

> [!NOTE]
> If you setup this, Invidious will check if the proxy is alive doing a request to `https://inv-proxy.example.com/health`, and if it doesn't get a response code of 200, Invidious will fallback to the local videoplayback proxy! This is only currently supported by https://git.nadeko.net/Fijxu/http3-ytproxy

- Limit the DASH resolution sent to the clients: It can be set using `max_dash_resolution` on the config. Example: `max_dash_resolution: 1080`

- [Limit requests made to Youtube API when pulling subscriptions (feeds)](https://git.nadeko.net/Fijxu/invidious/commit/df94f1c0b82d95846574487231ea251530838ef0): Due to the recent changes of Youtube ("This helps protect out community", "Sign in to confirm you are not a bot"), subscriptions now have limited information, this is because Invidious by default, makes a video request to youtube to be able to get more information about the video, like `length_seconds`, `live_now`, `premiere_timestamp`, and `views`. If you have a lot of users with a ton of subscriptions, Invidious will basically spam youtube API all the time, resulting in a block from youtube.

It can be set using this on `config.yml`:
```yaml
use_innertube_for_feeds: false
```

---

There is more things that I added to this fork, but those are the most important ones. I also regularly merge unmerged pull requests from https://github.com/iv-org/invidious and random fixes as well. Is not the most stable codebase, but you can't really make something stable when youtube is trying to destroy every third party client out there.