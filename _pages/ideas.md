---
layout: single
title: "Ideas"
permalink: /ideas/
toc: true
toc_label: "Ideas"
toc_icon: "lightbulb"
toc_sticky: true
comments: true
---

In an interview, Sam Altman said if he were 22, he would feel like the luckiest
kid in all of history. For the empowered individual, there is simply an
overwhelming abundance of projects worth pursuing and a frustrating scarcity of
time to do them.

Since I haven't yet found a way to build everything myself (still trying to),
I'm open-sourcing my backlog. This is a list of (half-baked) project concepts
I'd love to see brought to life. Some of these are taken from somewhere else.
Feel free to steal anything.

## Information understanding

### Betting as a substitute for polling

- As a famous saying goes, "A bet is a tax on bullshit".
- Use distributions on betting platforms to understand real mass opinion, better
  than polls.
- Remember the 2024 US presidential election - instead of asking "what do you
  feel", asking "what do you think your neighbor would feel" gave much more
  accurate responses and the French trader Theo made a fortune. There is
  headroom in mass opinion understanding.

### Crowdsourced Hot Takes Newsletter

- A weekly newsletter where you ask founders or business leaders for their take
  on an important question and share their takes with readers.
- Reach out to influential voices in the tech or business space asking them some
  big questions e.g. When will we reach AGI, are we in an AI bubble etc.
- Send out a weekly edition where you share the responses to one of these
  questions from the different thought leaders polled.
- Business Model: Sponsored placements in each issue + premium membership for
  archive / search / tools.
- End Goal: Potential acquirers include Substack / Morning Brew / Axios /
  HubSpot, LinkedIn, or X. Target 4-6x revenue once brand and data moat are
  established.

### User data collection

- How to collect data from individuals (e.g. product reviews) when not everyone
  is willing to manually write reviews?
- The value of human beings might just boil down to data collection and data
  annotation. Annotation might be more effective and noise-free if it's done via
  passive participation such as simple things like games and captcha, or simply
  observing the decisions they make. This should be done without formally paying
  someone and asking them to intentionally label for your tasks.
- Because if you think about it, humans are doing data annotation tasks all day
  on their own anyways! That's all they ever do.

### Noise as a fingerprint of origin

- If a certain dataset contains a certain type of noise, what can we say / do?

### Why are charts effective?

- Given the same information, why is a chart more productive compared to text
  description of the same thing? think about how machines & humans process this
  info.

### General visualization of outputs

- Why do we need all-text output when logic can be more clearly expressed using
  graphs?
- For example, if I ask for an explanation of the difference between big endian
  and little endian, the best response should include a graph or slide instead
  of text. The same can be said about conditional sentences, processes,
  conversations, and most topics.

## Modeling

### Distillation

- We can use a model to design a rubric & to judge, & for it to be used as a
  reward model for RL; this is a proven recipe that gives us a better model.
- But this means all that knowledge has been in the model in the first place,
  it’s just amplified through iterative self-reward.
- Is there a way to mine this knowledge upfront?
- Also, where can new learning come from? Maybe new learnings don’t need to come
  from a new dataset, they just need to come in another way from an existing
  model.

### Learning from the nature

- Shortest paths chosen by electric currents, whale songs, etc. These carry
  great amounts of information (think about the number of decisions they prune)
  but are under-utilized just because they can’t be very conveniently serialized
  as text. How to collect the data and learn from them?

### Using LLMs

- LLMs operate on next-token natural language prediction.
- As I'm writing in 2025, a lot of startups have offered LLMs in the quality of
  a chatbot or a conversation predictor.
- Selling LLMs in this way is like selling computers as calculators.
  - A CPU is built to do arithmetic (think about all a CPU can do, they are
    instructions like ADD, SUB, etc.).
  - In fact, arithmetic abilities are a general class ability because many
    problems can be framed in it. This makes a CPU a versatile machine that can
    solve a general class of problems. This makes computers generally valuable;
    not just for arithmetic but for this extension of it.
- Now LLMs are built to do next-token natural language prediction. But does this
  mean the most powerful products which can be built on LLMs have to stay on
  this surface?
- Most of the LLM startups of 2025 still try to package the LLM in a product
  that uses the natural language interface directly. Either as chatbots (to
  predict dialogs) or as coding agents (to predict code). This is very limiting.
- Hint: LLMs are valuable because they capture inter-token relations that very
  cheaply encode "common sense", above all else. Common sense used to be
  expensive.

### LLMs are post-trained with alignment

- We know that training on one front almost always results in loss in ability on
  other fronts.
- By "alignment" (making the model easier to use), we make the model less
  capable.
- So the best models might be intentionally not post-training aligned. The
  question is just how we will perform inference on them.
  - For example, we can't just ask such a model a question directly.

## Programming

### Balance between code and no-code

- Code is too hard to learn, but no-code is too unpredictable.
- Data types (chat, int32, int64, etc.) are just an artifact of how the computer
  likes to think about things. It is not how humans think. So it needs to be
  removed.
- But the current (2025) no-code tools where humans just issue one command and
  the whole thing gets built - is also suboptimal because when users can lose
  track of what happens.
- They actually want to enjoy the process of building, like putting together
  LEGO pieces. At the same time they don't want to be totally removed. In this
  process they want to involve as little computer-native thinking as possible.
- So, they want to code - just no data types, but still conditionals, functions,
  etc.
- The devil is in the detail, and sometimes humans don’t want to think of the
  detail. It is in this case that the AI can step up.
- It’s one thing to code up an algo but another thing to use database (Redis),
  multithreading, async, etc. to fully implement it.
- Distillation or best practices in this regard has the potential to be made
  into a new programming language, just like how Python was distilled as best
  practice for C programming, in part.

### Code understanding

- If you want to understand and contribute to the code base, LLM should give you
  a good starting point.

### Value analysis

- Analyze GitHub code and observe signals of commercialization & purchase.
  Startup founders need early benchmarks on their valuation.

### Contribution analysis

- Want to measure output of an engineer but how? Use a model to make the
  value of a code segment more measurable.

### Agentic coding softwares

- Agentic coding UI first incorporated AI chats as a side bar on the right, then
  some tools like Cursor moved it to the left. This represents a paradigm change
  where the user cares less about the code and more about the flow that they and
  the AI collaborate on.
- Now these softwares still show code by default. Maybe the user won't care so
  much about the exact code itself but would rather just see the AI chat on one
  side and a flowchart representation of the code on the other side?

## Languages

### Kid's bilingual toy

- Lots of immigrant parents in the US with cultural anxieties.
- A lovable interactive plush that gently introduces children (ages 2–6) to a
  second language through playful audio prompts, engaging storytelling, and
  responsive language games.

### Browser plugin

- Selectively translate some parts of page, choosing the most pertinent parts to
  translate based on your level.

## Online traffic

### Informatics video

- Embed informatics in a song! Like @learningwithlyrics on instagram

## Trading

### Bartering

- Money was invented because people did not have enough information to find
  partners (or chains of partners) for bartering. Does this condition still
  hold in 2025?
- When we use money to buy things, the price we are paying is impacted by how
  other people want the same thing. We don't necessarily want this.
- In bartering, a lot more trades can happen that will make everyone happier.
  See the Red Paperclip House.
- AI should allow bartering to happen in a lot more occasions.

### Compute as a currency

- Compute will be the most valuable commodity / currency in the world. Because
  it will be the most scarce commodity in the world. Because it won’t saturate
  too much - more compute will always be more valuable.
- By a similar logic, digital storage will also be the most valuable commodity /
  currency in the world.

### Personal shareholding

- Sell a part of yourself to shareholders at a price you agree on. They are
  entitled to a portion of your lifelong earnings in a designated period and
  will provide you with personal mentorship / resources.

### Entrepreneurship

- With AI there are countless good ideas. The real challenge is in the
  execution. But having ideas is very easy.
- Nevertheless, it is still valuable to have good ideas. See the success of the
  Half Baked newsletter for reference.
- Found a platform to share ideas & go one step further - make it easy &
  straightforward for people to contribute to ideas (jobs, brainstorm, capital,
  compute, etc)

## Misc

### Inter-agent communication

- HTTP for agents - highly effective & condensed communication between agents.
  Define Inter-Agent Communication Protocol (IACP). And then commercialize it by
  providing ecosystem infra like HTTP

### Too many browser tabs

- In a browser, when clicking a link to a new page, instead of going to a new
  tab, use a pop-up window - use the model to show the most relevant information
  on a new page, but stay on the current page

### Git for PPT

- As title

### NBU (Next Billion Users) for ChatGPT

- Essentially everybody can benefit from using an AI chatbot to offload some
  decision-making burden. But why isn't ChatGPT having a 8-billion DAU yet?
  It's because some people still either don't know it exists, or don't have
  reliable access to it (think laptops, electricity, internet, etc.)
- These people might not necessarily know how to download new apps & merge it to
  their daily routines.
- How is AI Mode a success? The core underlying model is not too different from
  what's on the Gemini endpoint. But it is closer to the user's existent
  routine.
- Chat model endpoint via SMS, or a phone hotline. Users prefer simplicity.

### Email agent

- How do CEOs manage their inbox? Assistants reply to emails for them. And by
  EOD or EOW they go over these decisions made on their behalf: meetings
  scheduled, pending items, etc. together in a standup meeting.
- Do the same with email agents - this will be better than an AI smart reply.
- As well, if everyone’s using AI, why not directly facilitate the exchange of
  information? Why still rely on text as if it’s written by someone?

### Messaging platform

- Turn on notification only if a condition is met. This condition can be natural
  language (e.g. notify only if the msg is relevant to me).
- Or could this be a theme / notif center capacity in Android?

### Voice mode for consumer apps

- People don’t like to start into a small screen. Think Duolingo, but voice
  only.

### Hiring

- Hiring is a promising market, at least for now. Think Mercor.
- LeetCode doesn’t work anymore.
- Competition-based hiring, think Kaggle.

### Vibe photography

- Vibe programming solves the problem of programming for people who don’t know
  how to program.
- For people who don’t know how to take good photos but have the need (think
  husband & wife), do we have vibe photography?
