---
title: SDL & Automation
description: Self-driving labs, automation, and sensors — starting from a $100 minimal working example and building toward my own SDL hardware pipeline.
---

Self-driving laboratories (SDLs) — systems that combine automated experimentation with AI-driven decision-making to close the loop between hypothesis, experiment, and the next hypothesis — are one of the more concrete ways AI is starting to reshape how chemistry and materials research actually gets done. The promise is real, but so is the barrier to entry: building a genuine SDL usually means combining expertise across robotics, electronics, and machine learning that most labs don't have in one place.

## A $100 entry point

Baird & Sparks' [*What is a minimal working example for a self-driving laboratory?*](https://doi.org/10.1016/j.matt.2022.11.007) (*Matter*, 2022) makes a compelling case that this barrier is more about accessibility than necessity. Their proposed "SDL-Demo" strips a self-driving lab down to its essential loop — a microcontroller adjusts a physical parameter (an RGB LED's brightness), a sensor measures the outcome (a spectrophotometer reads the resulting light mixture), and an optimization algorithm decides what to try next — using off-the-shelf components, for under $100, in under an hour of setup, on about a square foot of desk space. It's not materials chemistry, but it preserves the actual principles: closed-loop feedback, active learning, and cloud-assisted decision-making.

The paper's real argument is educational: a minimal, low-risk, hands-on example like this is exactly what interdisciplinary programs need to build genuine confidence with SDL concepts before committing to an expensive, high-stakes materials-discovery platform. That's a course design principle as much as a hardware spec, and it's one I think more programs bridging chemistry, robotics, and ML should take seriously.

## Building my own version

I'm currently working through my own SDL hardware pipeline — a Cytron Maker Pi Pico W, MicroPython, HiveMQ for MQTT messaging, and MongoDB for data storage, with a NeoPixel LED and an AS7341 spectral sensor — which lines up closely with the hardware Baird & Sparks propose. It's very much a work in progress (currently troubleshooting the usual first-build issues: WiFi credential handling, MQTT TLS certificates, sensor pin mapping), but the overlap with a published, peer-reviewed minimal example is a good sanity check that the approach is sound.

This ties directly into Sterling Baird's own SDL course — the same Sterling Baird behind this paper, now at Brigham Young University — which grounds the hands-on build in the broader theory of self-driving labs and materials acceleration platforms. I plan to take the course myself.

*More to come here as the build progresses.*

## Where to learn more

If you want to go deeper on self-driving labs, these are two places I'd start:

- [**The Matter Lab**](https://www.matter.toronto.edu/) — Alán Aspuru-Guzik's group at the University of Toronto, one of the leading research groups working on self-driving labs and AI-accelerated materials and chemistry discovery.
- [**Varinia Bernales**](https://bernales.org/) — Varinia's page, a great resource for anyone getting into SDLs, especially if you're interested in agentic platforms for quantum chemistry (check out the El Agente platform, for example).
