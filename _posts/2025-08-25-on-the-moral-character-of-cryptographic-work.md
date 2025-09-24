---
tags:
 - philosophy
title: "Reflecting on the moral character of cryptographic work"
#date: 2020-11-05 20:45:59
#published: false
permalink: moral-character
#sidebar:
#    nav: cryptomat
#article_header:
#  type: cover
#  image:
#    src: /pictures/.jpg
---

> I suspect that many of you see no real connection between social, political, and ethical values and what you work on. 
>
> You don’t build bombs, experiment on people, or destroy the environment. You don’t spy on populations.
>
> You hack math and write papers.
>
> This doesn’t sound ethically laden. I want to show you that it is.

--Phillip Rogaway, *“The Moral Character of Cryptographic Work”*[^Rog15]

<!-- Here you can define LaTeX macros -->
<div style="display: none;">$
$</div> <!-- $ -->

Two years after the Edward Snowden revelations, Phillip Rogaway[^rogaway] writes a position paper[^Rog15] on the political nature of cryptographic research and the values embedded in this work.

At the time, I am a graduate student, desperately trying to find my way as a researcher.

Rogaway's paper grounds me.
It gives me some much-needed reassurance that it is **good** to explore what I thought could be an important tool in the fight against mass surveillance: secure public key distribution (PKD) for end-to-end encrypted email and messaging.

So, I start learning a lot about Bitcoin and cryptographic accumulators and end up making some _practical_[^TD17] and some _academic_[^TBPplus19] progress on the PKD problem.
Then, I become a full-time researcher at VMware Research and get wonderfully-distracted by the joys of solving cryptographic puzzles.

Ten years later, I am reminded of his paper and I feel compelled to re-read it.

{: .info}
**tl;dr?** I do not have one. You will have to wrestle with the incredibly-nuanced implications of Rogaway's essay.

## Why this reflection?

If you came here for moral clarity, you are about to be very dissapointed.
I do not have a clear-cut answer to Rogaway's call to morality in cryptographic research.

I fear that in our incredibly-complex society, the common (and unfortunate) effect of calling for morality is to put people off or to exhaust them.
Perhaps this is understandable.
"Morality" can be nothing but a luxury for most of us, as our livelihood depends on working for someone else and thus on deferring morality to them or their superiors.
Plus, this is hardly the only difficulty.
Determining what it means for **you, personally,** to act morally in the world is no trivial task.
You could philosophically-investigate the manner (Aristotle, Kant, Stuart Mill, Rawls, etc.) but, as interesting and as informative as that may be, you may find that:

 > "In _theory_, practice and theory are the same. In **practice**, they are not."

More disturbingly, "morality" sometimes degenerates into performative virtue-signalling, turning into a weapon to be used against the "immoral."
This is not at all what this blog post is trying to do: you do you, man.
Live and let live.
<small>(In this case: exponentiate and let others exponentiate.)</small>

For me, a guiding principle is that my _immediate_ responsibilities to myself, to my family should probably trump my _remote_ responsibilities to our society.
After all, wouldn't it be arrogant (even dangerous?) to adopt responsibility for an entire nation when I barely have my own proverbial house in order?

Is this a free pass to completely neglect our broader responsibilities?
Not all.
Rogaway urges us not to and offers us [several paths forward](#what-should-cryptographers-do).
For some of us, all these paths may be inaccessible.
Nonetheless, all of us can at least recognize and wrestle with the political and social implications of our work.

Ideally, a small subset of us may even be able to exercise what they think are the _right_ choices.

### A hot take

At the end of the day, as cryptographers, we should not forget how incredibly **silly, and therefore dangerous,** the world we've let others build has become.

Take one example: identity fraud.
Your social security number (SSN) is required by law to be given to banks, medical providers and any other dimwit capable of losing it from their "secure" database.
We've managed to let the village idiot dictate our security policy.
Instead of using [digital signatures](/signatures), which are not vulnerable to numbskull verifiers getting hacked, some simpleton more or less said: _"Let's just use the same password with every verifier. What can go wrong?"_.

Meanwhile, 10% of adults in the US reported falling victim to identity theft, spending on average four hours dealing with the ensuing nonsense[^aarp].
On average, they lost a thousand bucks. In total, \$16 billion.

So, yes: _"share your sensitive data with everyone who 'needs' it,"_ why don't you?

_"It's for your own good! Otherwise, the criminals will win!"_

## What did we do?

### Towards surveillance tech

We, computer scientists (and cryptographers), could very well be considered **co-creators of the mass surveillance apparatus**:

>  [...] we are twice culpable when it comes to mass surveillance: computer science created the technologies that underlie our communications infrastructure, and that are now turning it into an apparatus for surveillance and control.

By **not aspiring towards the good** (privacy tech), we gravitated towards the bad (surveillance tech):

> I have observed that a **wish for right livelihood** almost never figures into the employment decisions of undergraduate computer science students.

(This makes me think of the Greek word for “sin”: “hamartia”, which roughly means "to miss the mark" or "to err.")

In general, Rogaway fears that, as a community, we may be somewhat-oblivious to **the inherently-political nature of our work**:

> Technological ideas and [...] things are not politically neutral: routinely, they have strong, built-in tendencies.
>
> That cryptographic work is deeply tied to politics is a claim so obvious that only a cryptographer could fail to see it.

### Ingoring the real adversary

 > In a declassified trip-report about Eurocrypt 1992[^eurocrypt-1992], the NSA author opines: 
 > _"There were no proposals of cryptosystems, no novel cryptanalysis of old designs, even very little on hardware design. I really don’t see how things could have been better for our purposes.”_

In light of the Snowden revelations, everyone should know how advanced "the adversary" $\mathcal{A}$ can be: three-letter intelligence agencies, the military-industrial complex and state governments.

 > **Cryptography is serious**, with ideas often hard to understand. 
 > When we try to explain them with cartoons and cute narratives, I don’t think we make our contributions easier to understand.
 >
 > Worse, the cartoon-heavy cryptography can reshape our internal vision of our role. 
 > The adversary as a \\$53-billion-a-year military-industrial-surveillance complex and the adversary as a red-devil-with-horns induce entirely different thought processes.

This is not at all to suggest that cryptographers should adopt an ultra-libertarian, anti-government stance.
But we should not be naive either: power abhors a vacuum.

And indeed, Rogaway strongly argues[^gellman-2013] that _"cryptography is about power. It’s a realm in which governments spend enormous sums of money."_

 > The U.S  Consolidated Cryptologic Program includes about 35,000 employees.
 > NSA budget for 2013 was \\$10.3 billion with \\$1 billion of this marked as 'cryptanalysis and exploitation services' and \$429 million [was marked as] 'research and technology.'

In fact, early in his career, Rogaway felt first-hand how the government wanted to curtail the power of his own cryptography, when the NSA almost denied his research funding:

 > In the USA, the NSA advises other DoD agencies on crypto-related grants. At least sometimes, they advise the NSF.
 > Back in 1996, the NSA tried to quash my own NSF CAREER award. I learned this from my former NSF program manager, Dana Latch, who not only refused the NSA request, but, annoyed by it, told me.

I think this makes Rogaway wonder whether the lack of progress on crypto for privacy is because _"funding agencies may not want to see progress in this direction"_, recalling the story of how the research that led to RSA was only **accidentally** funded by the government: 

 > An internal history of the NSA reports on the mistake of theirs that allowed funding the grant leading to RSA.
 > NSA had reviewed the Rivest [grant] application, but the wording was so general that the Agency did not spot the threat and passed it back to NSF without comment.
 > Since the technique had been jointly funded by NSF and the Office of Naval Research, NSA’s new director, Admiral Bobby Inman, visited the director of ONR to secure a commitment that ONR would get NSA’s coordination on all such future grant proposals.

Lastly, cutting funding is not even that aggressive of a move.
For example, the NSA has been known to intimidate universities in order to prevent their faculty from discussing the implications of its surveillance program.
One incident involves Matthew Green at John Hopkins University[^green-website]$^,$[^green-2013].
Another incident involves Barton Gellman at Purdue University[^gellman-2015].

### Mass surveillance misframed as a "privacy" vs. "security" issue

> "I think when they're 100,000+, they're not exactly targets." --Philip Rogaway, USENIX Sec’16

Government surveillance **should** be a well-known reality to folks:

 > History teaches that extensive governmental surveillance becomes political in character. For example, leveraging audio surveillance tapes, the FBI’s attempted to get Dr. Martin Luther King, Jr. to kill himself.

This should make us all ponder where our online conversations are going. 
For example, post 2022, large language models (LLMs) can now summarize all surveilled online communications and identify “targets”.

The following paragraph from Rogaway was almost prescient:

 > To be more prosaic: I pick up the phone and call my colleague, Mihir Bellare, or I tap out an email to him. How many copies of this communication will be stored, and by whom? What algorithms will analyze it—now and in the future? What other data will it be combined with in an attempt to form a picture of me? What would trigger a human analyst to get involved? Might my call or email contribute to a tax audit, a negative grant-funding decision, some Hoover-style dirty tricks, or even an assassination?

Surveillance should make us all worried about the future of political dissent:

 > I am far more concerned with what surveillance does to society and human rights. Totalized surveillance vastly diminishes the possibility of effective political dissent. And without dissent, social progress is unlikely.

We should not stop our worries at dissent either.
What if you want to gain political office, or disrupt a business sector?
Your competitors, working hand in hand with the surveillance apparatus may not let you:

 > A creeping surveillance that grows organically in the public and private sectors, that becomes increasingly comprehensive, entwined, and predictive, that becomes an instrument for assassination, political control, and the maintenance of power—well, this vision doesn’t merely seem possible, it seems to be happening before our eyes.

#### Misdirection: _"It's law-enforcement, not mass-surveillance."_

 > It is a brilliant discourse of fear: fear of crime; fear of losing our parents’ protection; even fear of the dark.

This misleading **law-enforcement framing**, _"as regularly communicated by (U.S.) FBI Director James Comey”_, goes as follows:

 > 1. **Privacy** is personal good. It’s about your desire to control personal information about you.
 > 2. **Security**, on the other hand, is a collective good. It’s about living in a safe and secure world.
 > 3. Privacy and security are inherently in conflict. As you strengthen one, you weaken the other. We need to find the right balance.
 > 4. Modern communications technology has destroyed the former balance. It’s been a boon to privacy, and a blow to security. Encryption is especially threatening. Our laws just haven’t kept up.
 > 5. Because of this, bad guys may win. The bad guys are terrorists, murderers, child pornographers, drug traffickers, and money launderers. The technology that we good guys use—the bad guys use it too, to escape detection.
 > 6. At this point, we run the risk of Going Dark[^going-dark]. Warrants will be issued, but, due to encryption, they’ll be meaningless. We’re becoming a country of unopenable closets. Default encryption may make a good marketing pitch, but it’s reckless design. It will lead us to a very dark place.

Yet, post Edward Snowden, we all know the **reality of mass surveillance**.
So, following _"often-heard thoughts from cypherpunks and surveillance studies"_, the right framing is:

> 1. **Surveillance** is an instrument of power. It is part of an apparatus of control. Power need not be in-your-face to be effective: subtle, psychological, nearly invisible methods can actually be more effective.
> 2. While surveillance is nothing new, technological changes have given governments and corporations an unprecedented capacity to monitor everyone’s communication and movement. Surveilling everyone has became cheaper than figuring out whom to surveil, and the marginal cost is now tiny. The Internet, once seen by many as a tool for emancipation, is being transformed into the most dangerous facilitator for totalitarianism ever seen.
> 3. Governmental surveillance is strongly linked to cyberwar. Security vulnerabilities that enable one enable the other. And, at least in the USA, the same individuals and agencies handle both jobs. Surveillance is also strongly linked to conventional warfare. As Gen. Michael Hayden has explained, _"we kill people based on metadata."_ Surveillance and assassination by drones are one technological ecosystem.
> 4. The law-enforcement narrative is wrong to position privacy as an individual good when it is, just as much, a social good. It is equally wrong to regard privacy and security as conﬂicting values, as privacy enhances security as often as it rubs against it.
> 5. Mass surveillance will tend to produce uniform, compliant, and shallow people. It will thwart or reverse social progress. In a world of ubiquitous monitoring, there is no space for personal exploration, and no space to challenge social norms, either. Living in fear, there is no genuine freedom.
> 6. But creeping surveillance is hard to stop, because of interlocking corporate and governmental interests. Cryptography offers at least some hope. With it, one might carve out a space free of power’s reach.

## What should we do?

> I plead for a reinvention of our disciplinary culture to attend not only to puzzles and math, but, also, to the societal implications of our work.

Rogaway’s essay gives plenty of guidance on what to do next:

### Remember our values

> Our collective behavior embodies values—and the institutions we create do, too.
>
> Your moral duties extend beyond the imperative that you personally do no harm: you have to try to promote the social good, too.

First, remember the history and purpose of cryptography:

 > Cryptography contains within it the underused potential to help redirect this tragic turn [towards mass surveillance and control].
 >
 > Neal Koblitz asserts that the **founding of the CRYPTO conference in 1981 was itself an act of deﬁance**.
 > 
 > Susan Landau reminds us that privacy reaches far beyond engineering, and into law, economics, and beyond. She reminds us that **minimizing data collection is part of the ACM Code of Ethics and Professional Conduct**.[^landau]
 >
 > [When] the IACR was founded, its self-described mission [was] not only to advance the theory and practice of cryptology but also, lest we forget, to serve the public welfare.

As an aside, you can actually see Koblitz describe the defiant nature of CRYPTO in a recent 40-year restrospective on elliptic curve cryptography:

<iframe width="467" height="263" src="https://www.youtube.com/embed/RWtqRcVkMvs?si=eBGODfldt8vkYX0Q" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

{: .note}
Funnily, back then, cryptographers were so unhinged, and CRYPTO was so rowdy, that a restriction had to be introduced **only** allowing audience members to throw **empty** beer cans at speakers! (Koblitz describes this [here](https://youtu.be/YtZowEkaE0o?t=3075).)

Returning to Rogaway's guidance: we must remember that (some of our) work is subsidized by society, and therefore, **is** for society.
I think this faces us with an almost-impossible moral task that we must nonetheless tackle.

 > Scientists and engineers have **an obligation to select work that promotes the social good**, or, at the very least, to refrain from work that damages mankind or the environment. The obligation stems from three basic truths.
 >  - the work of scientists and engineers transforms society,
 >  - this transformation can be for the better or for the worse,
 >  - what we do is arcane enough that we bring an essential perspective to public discourse.
 >
 > It can be impossible to foresee if a line of work is going to be used for good or for ill. [...]
 > Despite such difficulties, **the socially-engaged scientist** is supposed to investigate, think, and decide what work he will or will not do, and what organizations he will or will not work for.
 >
 > Our work as academics, we should never forget, is **subsidized by society**.

{: .note}
The passage above reminds me of a pertinent esssay on the political nature of technologies[^artifacts].

Second, remember cypherpunk values[^cypherpunk-manifesto]:

 > The cypherpunks believed that a key question of our age was whether state and corporate interests would eviscerate liberty through electronic surveillance and its consequences, or if, instead, people would protect themselves through the artful use of cryptography.
 >
 > The cypherpunks did not seek a world of universal privacy: many wanted privacy for the individual, and transparency for the government and corporate elites.
 >
 > Where, after Chaum, did the moral soul of academic cryptography go?

Third, remember to pick your research problems not only by looking inward at what the cryptographic community wants but also by **looking outward** at what broader society _needs_.

 > Perhaps every field eventually becomes primarily self-referential.
 > Maybe this is even necessary, to some extent.
 > But for cryptography, much is lost when we become **so inward-looking that almost nobody is working on problems we could help with that address some basic human need.**
 > 
 > I do not intend to criticize any particular individual.
 > People should and will work on what they think to be most valuable.
 > **The problem occurs when our community, as a whole, systematically devalues utility or social worth**.
 > Then we have a collective failure.
 > The failure falls on no one in particular, and yet it falls on everyone.
 >
 > **Choose your problems well.
 > Let values inform your choice.**
 > Many times I have spoken to people who seem to have no real idea why they are studying what they are.
 > The real answer is often that they can do it, it gets published, and that people did this stuff before.
 > These are lousy reasons for doing something.
 > Introspection can't be rushed.
 > In the rush to publish paper after paper, who has the time?
 >
 > I think we should breathe, **write fewer papers, and have them matter more.**

### Do not accept morally-hazardous funding

> The military funding of science invariably redirects it and creates moral hazards. [...] No matter what people say, our scientific work does change in response to [a] sponsor’s institutional aims.

Consider that it may actually matter where the research grant money comes from:

 > Neal Koblitz [...] warns of the **corrupting role that funding can play**.
 >
 > In the United States, [...] the **majority of extramural cryptographic funding may now come from the military**.
 >
 >   - From 2000 to 2010, fewer than **15%** of the papers at CRYPTO that acknowledged U.S. extramural funding acknowledged DoD funding.
 >   - In 2011, this rose to **25%**.
 >   - From 2012 to 2015, it rose to **65%**.
 >
 > I would suggest that if a funding agency embraces values inconsistent with your own, then maybe you shouldn’t take their money. **Institutions have values, no less than men.** Perhaps, in the modern era, they even have more.

The obvious implication is that we need alternative funding methods.
Cryptocurrencies may actually be able to help here.

In many ways they already have.
The last 10 years of exciting developments in zero-knowledge proofs were, I think, mainly due to cryptocurrency applications and funding.
For example, consider the pioneering work done by the [Zcash team](https://z.cash/), the [circom](/circom) ZK tooling by Polygon's [iden3](https://iden3.io/) efforts, or AZTEC's [Noir](https://aztec.network/noir) ZK tooling (and many more).

In light of all of the scams, the grifting and the insubstantive marketing claims, perhaps the saving grace of cryptocurrencies is that, at least the cypherpunk-aligned ones, offered cryptographers a viable way to step away from the military-industrial(-academic) complex, something that Rogaway called for in 2015:

 > In his farewell address of 1961, President Dwight D. Eisenhower introduced the phrase, and concept, of the military-industrial complex. 
 > In an earlier version of that speech, Eisenhower tellingly called it the **military-industrial-academic complex**.
 > If scientists wish to reverse our complicity in this convergence of interests, maybe we need to step away from this trough.
 >
 > A major reason that crypto-for-privacy has fared poorly may be that funding agencies may not want to see progress in this direction, and most companies don’t want progress here, either. 
 > Cryptographers have internalized this.
 > Mostly, we’ve been in the business of helping business and government keep things safe.
 > Governments and companies have become our “customers,” not some ragtag group of activists, journalists, or dissidents, and not some abstract notion of the people.
 > **Crypto-for-privacy will fare better when cryptographers stop taking DoD funds** and, more than that, start thinking of a very different constituency for our output.

### Ask _“Who are we empowering?”_

> [It has been said that] just because you don’t take an interest in politics, doesn’t mean politics won’t take an interest in you.
>
> Since cryptography is a tool for shifting power, the people who know this subject well, like it or not, inherit some of that power.
>
> As a cryptographer, you can ignore this landscape of power, and all political and moral dimensions of our ﬁeld. But that won’t make them go away. It will just tend to make your work less relevant or socially useful. 
>
> My hope [...] is that you will internalize this fact and recognize it as the starting point for developing an ethically driven vision for what you want to accomplish with your scientific work.

Once again, we come back to Rogaway's claim that "cryptography is about power." 

 > If a content-provider streams an encrypted ﬁlm to a customer who holds the decryption key locked within a hardware or software boundary she has no realistic ability to penetrate, **we’ve empowered content providers, not users.**
 >
 > If we couple public-key cryptography with a key-escrow system that the FBI and NSA can exploit, **we empower governments, not people.**

A good example of how cryptographic primitives (may fail to) redistribute power is [identity-based encryption (IBE)](/pairings#identity-based-encryption-ibe):

 > **IBE**? [...] The aim is to allow a party’s email address, for example, to serve as his public key. 
 > [...] this convenience is enabled by a radical change in the trust model: Bob’s secret key is no longer self-selected.
 > It is issued by a trusted authority.
 > That authority knows everyone’s secret key in the system.
 >
 > Descriptions of IBE don’t usually emphasize the change in trust model.
 > And the key-issuing authority seems never to be named anything like that: it’s just the **PKG**, for *Private Key Generator*.
 > This sounds more innocuous than it is, and more like an algorithm than an entity.
 >
 > For example, the Wikipedia entry 'ID-based encryption' (Nov. 2015) has a lead section that fails to even mention the presence of a key-issuing authority.
 > One can easily see the authoritarian tendency built into IBE.
 > And technologies, while adaptable, are not inﬁnitely so. As they evolve, they tend to retain their implicit orientation.

(FWIW, I do think one _can_ find productive ways to use IBE. For example, you can build batched threshold decryption schemes[^AFP24e] that may help mitigate a large class of toxic MEV on cryptocurrency exchanges.)

### Work on post-Snowden cryptography

 > Cryptography can be developed in directions that tend to beneﬁt the weak or the powerful.
 > It can also be pursued in ways likely to beneﬁt nobody but the cryptographer.

Rogaway reflects on what Edward Snowden wrote:

 > _"In words from history, let us speak no more of faith in man, but bind him down from mischief by the chains of cryptography."_
 >
 > When I first encountered such discourse, I smugly thought the authors were way over-promising: they needed to tone down this rhetoric to be accurate. **I no longer think this way**.
 >
 > It wasn't until Snowden that I finally internalized that the surveillance issue was grave, was closely tied to our values and our profession, and was being quite misleadingly framed.
 >
 > We need to realize popular services in a secure, distributed, and decentralized way, powered by free software and free/open hardware. We need to build systems beyond the reach of super-sized companies and spy agencies.
 > Such services must be based on strong cryptography.
 > Emphasizing that prerequisite, we need to **expand our cryptographic commons.**

Dan Bernstein[^djb] speaks of two ways of doing crypto, _"interesting crypto and boring crypto,”_ urging the community to do more boring crypto!

 > **Interesting crypto** is crypto that supports plenty of academic papers.
 >
 > **Boring crypto** is 'crypto that simply works, solidly resists attacks, [and] never needs any upgrades.'
 >
 > Dan asks, in his typically flippant way:
 > "What will happen if the crypto users convince some crypto researchers to actually create boring crypto? 
 > No more real-world attacks.
 > No more emergency upgrades.
 > Limited audience for any minor attack improvements and for replacement crypto.
 > This is an existential threat against future crypto research.

Lastly, Rogaway is skeptical of doing crypto for crypto's sake.

 > Arvind Narayanan suggests a simple taxonomy for cryptographic work: there's crypto-for-security and crypto-for-privacy. [...] but he fails to mention that most academic cryptography isn't really crypto-for-security or crypto-for-privacy: it is, one could say, **crypto-for-crypto**.

This last point is where I think more nuance is needed.
For example, in 1986, [zero-knowledge proofs (ZKPs)](/zkps) could have been easily dissmissed as "crypto-for-crypto".
But, in 2025, ZKPs are at the forefront of "crypto-for-privacy" (e.g., Zcash[^BCGplus14e]), of "crypto-for-security" (e.g., [key management in cryptocurrencies](/keyless)), and of "crypto-for-scaling" (e.g., [Ethereum rollups](https://ethproofs.com)).
So, ZKPs are certainly not "boring crypto."
They are very much "interesting crypto," but of the useful kind.

In other words, it may not be immediately-obvious where to draw the line between "crypto-for-crypto" and "crypto-for-$x$."
For example, in 2015, Rogaway's position paper mentions over-exuberance around FHE and iO.
But, in 2025, some brave souls[^machina-io] may be making some exciting progress on improving and implementing iO.
And there are certainly many companies and researchers implementing practical FHE (e.g., Apple[^apple-fhe]!).

This isn't to say that Rogaway's argument around mis-placed funding is wrong, but it is to say that it can be very hard to estimate the time horizon in which "crypto-for-crypto" morphs into "crypto-for-privacy."

### Remember who the adversary is

 > Whimsical adversaries engender a chimerical ﬁeld.

Rogaway urges us to consider real-world, **post-2013**, threat models in our research:

 > I think **we would do well to put ourselves in the mindset of a real adversary**, not a notional one: the well-funded intelligence agency, the profit obsessed multinational, the drug cartel:
 >  1. You have an enormous budget.
 >  2. You control lots of infrastructure.
 >  3. You have teams of attorneys more than willing to interpret the law creatively.
 >  4. You have a huge portfolio of zero-days.
 >  5. You have a mountain of self-righteous conviction.
 >  6. Your aim is to 'Collect it All, Exploit it All, Know it All.'
 >  7. What would frustrate you?
 >  8. What problems do you not want a bunch of super-smart academics to solve?

### Choose language well

> Communication is integral to having an impact.

We could talk about having "privacy" or we could talk about "thwarting mass surveillance."
The latter language is more serious and thus more appropriate.

 > The word **privacy**, its meaning abstract and debated, its connotations often negative, is not a winning word.
 > Privacy is for medical records, toileting, and sex -- not for democracy or freedom.
 > The word **anonymity** is even worse: modern political parlance has painted this as nearly a ﬂavor of terrorism.
 >
 > We should try to speak of **thwarting mass surveillance** more than enhancing privacy, anonymity, or security.
 >
 > Concretely, research that aims to undermine objectionable surveillance might be called **anti-surveillance research**.
 > Tools for this end would be anti-surveillance technologies.
 > And choosing the problems one works on based on an ethical vision might be called conscience-based research.

## Parting thoughts

Lastly, although cryptography is about power, it is important to understand its limitations:

 > In a world where intelligence agencies stockpile and exploit countless vulnerabilities, obtain CA secret keys, subvert software-update mechanisms, infiltrate private companies with moles, redirect online discussions in favored directions, and exert enormous influence on standards bodies, cryptography alone will be an ineffectual response. At best, cryptography might be a tool for creating possibilities within contours circumscribed by other forces.

This makes me think of (and be grateful to) all the people who have contributed so much to anti mass surveillance technologies.

## References

For cited works, see below 👇👇

[^aarp]: [Identity Fraud Cost Americans $43 Billion in 2023](https://www.aarp.org/money/scams-fraud/identity-fraud-report-2024/), by Christina Ianzito, April 10th, 2024
[^apple-fhe]: [Combining Machine Learning and Homomorphic Encryption in the Apple Ecosystem](https://machinelearning.apple.com/research/homomorphic-encryption), by Machine Learning Research at Apple
[^artifacts]: [Do artifacts have politics?](https://faculty.cc.gatech.edu/~beki/cs4001/Winner.pdf), by Langdon Winner, 1980
[^cypherpunk-manifesto]: [A Cypherpunk's Manifesto](https://www.activism.net/cypherpunk/manifesto.html), by [Eric Hughes](https://en.wikipedia.org/wiki/Eric_Hughes_(cypherpunk)), March 9th, 1993
[^djb]: Daniel J. Bernstein's [personal page](https://cr.yp.to/djb.html)
[^eurocrypt-1992]: Eurocrypt 1992 reviewed. Author name redacted. National Security Agency, CRYPTOLOG. First issue of 1994. [[URL]](http://tinyurl.com/eurocrypt1992)
[^gellman-2013]: Barton Gellman and Greg Miller, 'Black budget' summary details U.S. spy network's successes, failures, and objectives; The Washington Post, April 29, 2013.
[^gellman-2015]: [I showed leaked NSA slides at Purdue, so feds demanded the video be destroyed](https://arstechnica.com/tech-policy/2015/10/i-showed-leaked-nsa-slides-at-purdue-so-feds-demanded-the-video-be-destroyed/), by Barton Gellman, October 8th, 2015
[^going-dark]: The “Going Dark” phrase (and its capitalization) is from James Comey's speech at the Brookings Institute, on October 16th, 2024: ["Going Dark: Are Technology, Privacy, and Public Safety on a Collision Course?"](http://tinyurl.com/comey-going-dark).
[^green-website]: Matthew Green's [personal blog](https://blog.cryptographyengineering.com/)
[^green-2013]: [John Hopkins and the case of the missing NSA blog post](https://www.propublica.org/article/johns-hopkins-and-the-case-of-the-missing-nsa-blog-post), by Jeff Larson and Justin Elliott, September 9th, 2013
[^landau]: [Viewpoints: Privacy and security: A multidimensional problem](https://dl.acm.org/doi/fullHtml/10.1145/1400214.1400223), by Susan Landau, in Communications of the ACM Volume 51, Number 11, 2008
[^machina-io]: [Hello, world: The first signs of practical $i\mathcal{O}$](https://machina-io.com/posts/hello_world_first.html), by Sora Suegami, Enrico Bottazzi, Pia Park, April 28th, 2025 
[^rogaway]: Phillip Rogaway's [academic webpage](https://www.cs.ucdavis.edu/~rogaway/)

{% include refs.md %}
