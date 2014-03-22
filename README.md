fireman
===

Easy push notifications for firebase apps.

You probably shouldn't use this in production.

This server listens to the messaging queue located at `pushQueue` on the root of the firebase, and sends push notifications to devies using the apple push notification server api.