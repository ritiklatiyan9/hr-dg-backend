# DWR design and measurement envelope

The existing emerald, graphite and warm-neutral design is extended with a report
table, filters, a focused editor, history, review reasons and print view. Compact
report summaries connect to web and Flutter homes. Mobile Home / Work / Inbox / Me
remain intact. Navigation follows capabilities; unavailable provider setup offers
manual work. Review actions also use each record's allowed actions.

Both clients expose completed/pending/blockers/next-day plan/clarification fields,
explicit Not stated versus None, transcript correction, attachment access and
explicit submission confirmation. Flutter shows Idle, Recording, Uploading,
Transcribing, Structuring, Preview, Submitting, Submitted and Recoverable error.
The normal prompt suggests 10–15 seconds of speech while allowing up to 120 seconds
and manual entry. There is no auto-submit, countdown penalty or timed draft deletion.
Native streaming avoids plaintext microphone temporary files. Local recording may
be encrypted only after the site's offline-draft setting is approved.

Printable reports use A4 margins and readable type. Ordinary short reports fit a
page; longer content flows to further pages. Nothing is clipped or shrunk to force
a single page. Attachments and restricted provenance are not embedded in the print.

## Latency/quality test envelope — NOT RUN against real providers

Target: recording stop to editable preview p95 below 8 seconds, with a total normal
journey around 30 seconds. These are UX targets, not measured guarantees. Each
client records upload, transcription, structuring and total preview timing.

Reproducible acceptance run after credentials/configuration are approved:

1. Record device model/OS/build, microphone/locale, app commit or artifact hash,
   API region, model/provider IDs, prompt/schema versions and provider account tier.
2. Verify Groq's account limits, including requests and audio quotas, in the
   actual account. Set admission/budget values below the applicable shared limits.
   Record existing consumers of those keys. Do not infer limits from free-tier
   marketing or use paid burst traffic without authorization.
3. Use 10–15 second, mono 16 kHz PCM recordings: 480 kB maximum for 15 seconds.
   Test a documented Wi-Fi/4G envelope of at least 10 Mbps upstream, RTT at most
   100 ms to the API and packet loss below 1%. Record measured network conditions.
4. Run at least 100 consented/synthetic utterances at configured concurrency,
   with Hindi/Hinglish/English, the supplied example, negation, incomplete work,
   uncertain names, silence and background noise. Log IDs and timings only;
   store reviewed speech/transcripts privately under the approved retention policy.
5. Report upload, each provider stage and stop-to-preview p50/p95/max, failure
   rate, cooldown/retry counts and admission rejections. Count manual fallback as
   a failure of AI preview latency, not a fast AI success. Separate cold/warm runs
   and shift-end bursts. Report the quota consumed and observed response headers.
6. Have bilingual reviewers compare each draft with speech/transcript. Record
   invented details, polarity/negation loss, uncertain-name handling and explicit
   absence versus unspecified fields. Require no invented hours/approval/payment
   in the example. Correctness takes precedence over a fast but wrong preview.

Current deterministic provider tests use mocks with real local PostgreSQL and
private S3. Their runtime is not provider p95 evidence. Actual account limits,
retention settings and model support remain unverified because credentials and
approved model/provider settings have not been supplied.

## References checked during implementation

- [Groq speech-to-text](https://console.groq.com/docs/speech-to-text): multilingual
  transcription endpoint, whisper-large-v3 and verbose diagnostic output.
- [Groq rate limits](https://console.groq.com/docs/rate-limits): actual account limits
  and quota response headers; do not assume one universal free quota.
- [OpenRouter structured outputs](https://openrouter.ai/docs/guides/features/structured-outputs):
  JSON Schema, strict output and supported provider parameters.
- [record 7.1.1](https://pub.dev/packages/record): maintained native microphone
  integration, PCM streaming and Android/iOS permission declarations.

The runtime OpenRouter DWR model is an operator-configured application dependency.
It is independent of the Codex model used to build this repository.
