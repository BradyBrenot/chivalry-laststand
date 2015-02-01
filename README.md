chivalry-laststand
=================

A team-based game mode.

One team has infinite respawns, the other spawns only once. Teams switch after the defenders are wiped out. The team that held out the longest as the defending team wins the round, with bonus time given for kills inflicted on the attackers.

Played on LTS or TDM maps, though tailor-made maps could be done. Note that, rather than swapping players' teams, it changes the game mode's spawn logic to spawn players at the opposing team's spawn points; therefore, it can't be used on any maps with Kismet or other features that rely on certain teams being in certain places. I'm not right now whether any such maps exist, but I figured I'd mention it. Can be played online, or offline with bots.

Takes LTS, then overrides ChoosePlayerStart, Scoring, EndRound, and other bits to accomplish what it needs.