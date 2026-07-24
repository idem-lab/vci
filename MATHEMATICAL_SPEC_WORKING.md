# Vectorial Capacity R Package: Working Mathematical Specification

**Status:** Working draft for review  
**Date:** 2026-07-22  
**Purpose:** Capture the mathematical decisions made so far before continuing component-by-component review. Confirmed decisions are stated directly. Unresolved items are labelled explicitly.

## 1. Scope of vectorial capacity

The framework is deliberately vector-focused. It includes human-to-mosquito infection probability, but excludes mosquito-to-human transmission probability because the latter depends substantially on human immunity, prophylaxis, and other human-side processes outside scope.

The stationary Garrett-Jones form is:

$$
V_{s,i,t}
=
c_{s,i,t}
\frac{m_{s,i,t}a_{s,i,t}^{2}p_{s,i,t}^{\nu_{s,i,t}}}
{-\log(p_{s,i,t})}.
$$

Here:

- $s$ is mosquito species;
- $i$ is location;
- $t$ is time or reporting period;
- $V_{s,i,t}$ is vector-side transmission potential attributable to species $s$;
- $c_{s,i,t}$ is the probability that a mosquito becomes infected after biting an infectious human;
- $m_{s,i,t}$ is adult mosquitoes of species $s$ per human;
- $a_{s,i,t}$ is the realised, successful, species-specific human blood-feeding rate per mosquito per day;
- $p_{s,i,t}$ is daily adult survival probability;
- $\nu_{s,i,t}$ is the extrinsic incubation period in days.

No mosquito-to-human transmission term $b_s$ is included. Downstream epidemiological models may combine these outputs with human susceptibility, immunity, prophylaxis, and other transmission components.

## 2. Temperature-history effects on infection and parasite development

The human-to-mosquito infection probability and EIP may depend on the full hourly mosquito-experienced temperature trajectory, rather than only its mean and variation.

Let:

$$
\mathbf T^{(h)}_{s,i,t_0:t}
=
\{T^{(h)}_{s,i,u}:u=t_0,\ldots,t\}
$$

be the species-specific hourly temperature history. A general component is:

$$
(c_{s,i,t_0},\nu_{s,i,t_0})
=
\mathcal P_s\!\left[
\mathbf T^{(h)}_{s,i,t_0:t};
\boldsymbol\theta_s^P
\right].
$$

The Stopard temperature-dependent model of human-to-mosquito transmission probability and EIP is a candidate implementation and parameter source.

For an accumulated-development implementation:

$$
r^P_{s,i,u}=f_s^P(T^{(h)}_{s,i,u}),
$$

and parasite development completes at:

$$
t_\star
=
\inf\left\{
t>t_0:
\sum_{u=t_0}^{t}r^P_{s,i,u}\Delta u\geq1
\right\},
$$

where $\Delta u=1/24$ day for hourly input. Then:

$$
\nu_{s,i,t_0}=t_\star-t_0.
$$

## 3. Survival through the EIP

The preferred formulation calculates survival along the realised incubation trajectory:

$$
S^{\mathrm{EIP}}_{s,i,t_0}
=
\prod_{u=t_0}^{t_\star}p^{(h)}_{s,i,u},
$$

where $p^{(h)}_{s,i,u}$ is hourly survival probability.

The stationary simplification remains available as a named assumption:

$$
S^{\mathrm{EIP}}_{s,i,t_0}
=
p_{s,i,t_0}^{\nu_{s,i,t_0}}.
$$

## 4. Expected future infectious biting

With time-varying survival and biting, replace the stationary remaining-lifespan factor with expected future successful human biting after parasite development:

$$
\Lambda_{s,i,t_\star}
=
\sum_{u=t_\star}^{\infty}
a_{s,i,u}
\prod_{v=t_\star}^{u}p_{s,i,v}.
$$

The trajectory-based vectorial-capacity contribution from mosquitoes infected at $t_0$ is:

$$
\boxed{
V_{s,i,t_0}
=
c_{s,i,t_0}m_{s,i,t_0}a_{s,i,t_0}
S^{\mathrm{EIP}}_{s,i,t_0}
\Lambda_{s,i,t_\star}
}.
$$

Under stationary $a$, $p$, and $\nu$, this recovers the Garrett-Jones-compatible expression. The implementation must state its continuous- or discrete-time mortality convention explicitly.

## 5. Maximum effective larval habitat

Define:

$$
L^{\max}_{s,i}\geq0
$$

as maximum effective larval habitat for species $s$ at location $i$.

$L^{\max}_{s,i}$ is:

- unitless;
- species-specific and spatially varying;
- temporally static;
- estimated from vector occurrence and abundance data;
- scaled relative to the habitat setup represented by the mechanistic population model;
- a latent combination of physical habitat extent, habitat suitability, habitat quality, and local productivity, not a physical area.

The shorter $L_{s,i}$ may be used in diagrams only if explicitly defined as maximum effective larval habitat.

## 6. Temporally varying realised aquatic habitat

Let:

$$
\rho_{s,i,u}\in[0,1]
$$

be the mechanistically modelled fraction of maximum effective larval habitat available at fine-resolution time $u$. It changes through rainfall accumulation, evaporation, leakage, overflow, and related water-balance processes.

The realised effective aquatic habitat is:

$$
A_{s,i,u}=L^{\max}_{s,i}\rho_{s,i,u},
$$

with:

$$
0\leq A_{s,i,u}\leq L^{\max}_{s,i}.
$$

$A_{s,i,u}$ is an internal mechanistic quantity, not an independently estimated spatiotemporal surface.

## 7. Population dynamics

Reserve lower-case $l_{s,i,u}$ for the aquatic-stage mosquito population or density inside the mechanistic population model. It is distinct from upper-case $L^{\max}_{s,i}$.

Let:

$$
\mathbf z_{s,i,u}
=
\begin{pmatrix}
n_{s,i,u}\\
l_{s,i,u}
\end{pmatrix},
$$

where $n_{s,i,u}$ is simulated adult mosquitoes per unit maximum effective habitat. The process is represented generally by:

$$
\mathbf z_{s,i,u+\Delta u}
=
\mathcal G_s\!\left(
\mathbf z_{s,i,u},
\rho_{s,i,u},
\mathbf C_{s,i,u};
\boldsymbol\theta_s^{\mathrm{pop}}
\right),
$$

where $\mathbf C_{s,i,u}$ contains species-specific microclimate inputs. `mosmicrosim` is the intended implementation source for the microclimate and population-dynamics components.

## 8. Adult abundance and temporal aggregation

At fine temporal resolution:

$$
M^{\mathrm{latent}}_{s,i,u}
=
L^{\max}_{s,i}n_{s,i,u}.
$$

For reporting period $t$, initially a calendar month:

$$
\bar n_{s,i,t}
=
\frac{1}{|\mathcal U_t|}
\sum_{u\in\mathcal U_t}n_{s,i,u}.
$$

Then:

$$
\bar M_{s,i,t}=L^{\max}_{s,i}\bar n_{s,i,t},
$$

and:

$$
\boxed{
m_{s,i,t}
=
\frac{L^{\max}_{s,i}\bar n_{s,i,t}}{H_{i,t}}
}.
$$

The monthly arithmetic mean is an initial downstream-use choice, not a permanent definition. Alternative aggregation operators must be supported.

Because vectorial capacity is nonlinear, distinguish:

$$
V(\bar m,\bar a,\bar p,\bar c,\bar\nu)
$$

from:

$$
\overline{V(m_u,a_u,p_u,c_u,\nu_u)}.
$$

These are not generally equal.

## 9. Estimating maximum effective habitat

The multispecies distribution and abundance model uses mechanistically predicted adults per unit maximum effective habitat as an offset when estimating spatial variation in $L^{\max}_{s,i}$.

A generic observation model is:

$$
Y_{s,j}\sim\mathcal D(\mu_{s,j},\phi_s),
$$

with:

$$
\log\mu_{s,j}
=
\log\bar n_{s,i_j,t_j}
+
\log L^{\max}_{s,i_j}
+
\text{covariate and observation-process terms}.
$$

Equivalently:

$$
\mu_{s,j}
=
\bar n_{s,i_j,t_j}L^{\max}_{s,i_j}q_j,
$$

where $q_j$ describes sampling effort, method, detection, and other observation-process effects. `va_multispecies_sdm` is the intended implementation source.

## 10. Attempted feeding rate

Define $a^*_{s,i,u}$ as the species-specific rate at which one adult mosquito attempts to obtain a blood meal under the prevailing temperature or microclimate, before host selection, human availability, or protection from bites.

$$
a^*_{s,i,t}
=
\mathcal A_s^*\!\left[
\mathbf T^{(h)}_{s,i,u};
\boldsymbol\theta_s^a
\right]_{u\in\mathcal U_t}.
$$

Its temporal aggregation rule must be explicit and configurable.

## 11. Human landing catch observation model

HLC counts mosquitoes landing on a collector during a fixed sampling period. Under this framework, HLC is closest to an observation of $m_sa_s^*$, not the intervention-adjusted successful human-biting quantity $m_sa_s$.

$$
Y^{\mathrm{HLC}}_{s,j}
\sim
\mathcal D\!\left(
E_jq^{\mathrm{HLC}}_{s,j}
\omega^{\mathrm{sample}}_{s,j}
m_{s,i_j,t_j}a^*_{s,i_j,t_j},
\phi_s
\right),
$$

where:

- $E_j$ is collector-time or other sampling effort;
- $q^{\mathrm{HLC}}_{s,j}$ captures protocol, collector, capture efficiency, setting, and other observation effects;
- $\omega^{\mathrm{sample}}_{s,j}$ is the share of the daily attempted-biting profile represented by sampled hours;
- $\phi_s$ is a dispersion parameter.

HLC alone identifies an abundance-biting product. Mechanistic prediction of $a_s^*$ from temperature provides the external structure used to separate $m_s$ and $a_s^*$. This is required because successful human biting is squared in vectorial capacity.

## 12. Species-specific timing and setting of biting attempts

The host-choice component must support parameterised species-specific hourly profiles of indoor and outdoor biting attempts:

$$
\lambda^{\mathrm{in}}_{s,i,t,h}
\quad\text{and}\quad
\lambda^{\mathrm{out}}_{s,i,t,h},
\qquad h\in\{1,\ldots,24\}.
$$

These may depend on species, temperature, season, and other predictors:

$$
\lambda^e_{s,i,t,h}
=
\mathcal B_s^e\!\left(
h,
\mathbf T^{(h)}_{s,i,t},
\mathbf x_{i,t};
\boldsymbol\theta_s^B
\right),
\qquad e\in\{\mathrm{in},\mathrm{out}\}.
$$

The model in `modd-africa/hackthon2026` pull request 1 is a candidate parameterised implementation and must be reviewed directly before encoding its equations.

If outputs are relative intensities:

$$
\widetilde\lambda^e_{s,i,t,h}
=
\frac{\lambda^e_{s,i,t,h}}
{\displaystyle\sum_{h'=1}^{24}\sum_{e'\in\{\mathrm{in},\mathrm{out}\}}\lambda^{e'}_{s,i,t,h'}}.
$$

## 13. Host opportunity before interventions

Let $u^{\mathrm{in}}_{i,t,h}$ and $u^{\mathrm{out}}_{i,t,h}$ be hourly human availability indoors and outdoors. Let $A^{\mathrm{host}}_{i,t}$ be non-human host availability. Let $w_s^{\mathrm{in}}$, $w_s^{\mathrm{out}}$, and $w_s^{\mathrm{animal}}$ be species-specific relative attraction or accessibility weights.

$$
G^{\mathrm{in}}_{s,i,t}
=
w_s^{\mathrm{in}}
\sum_{h=1}^{24}
\lambda^{\mathrm{in}}_{s,i,t,h}u^{\mathrm{in}}_{i,t,h},
$$

$$
G^{\mathrm{out}}_{s,i,t}
=
w_s^{\mathrm{out}}
\sum_{h=1}^{24}
\lambda^{\mathrm{out}}_{s,i,t,h}u^{\mathrm{out}}_{i,t,h},
$$

and:

$$
G^{\mathrm{animal}}_{s,i,t}
=
w_s^{\mathrm{animal}}A^{\mathrm{host}}_{i,t}.
$$

### Open notation choice

A single symbol for destination fractions has not been confirmed. Candidates include $\eta$, $\pi$, $\phi$, and $q$. $\pi$ risks conflict with species-composition notation. For now, use descriptive symbols $P^{\mathrm{in}}$, $P^{\mathrm{out}}$, and $P^{\mathrm{animal}}$.

The pre-intervention destination probabilities are:

$$
P^{e,0}_{s,i,t}
=
\frac{G^e_{s,i,t}}
{G^{\mathrm{in}}_{s,i,t}+G^{\mathrm{out}}_{s,i,t}+G^{\mathrm{animal}}_{s,i,t}},
$$

for $e\in\{\mathrm{in},\mathrm{out},\mathrm{animal}\}$.

## 14. Mapping interventions to effects

Intervention types do not have generic multiplicative residual effects. An intervention model maps the deployed scenario to mechanistic effect channels:

$$
\text{intervention scenario}
\longrightarrow
(R_{s,i,t},B_{s,i,t},K_{s,i,t}).
$$

- $R_{s,i,t}$: residual accessibility of indoor humans after repellency;
- $B_{s,i,t}$: residual probability of successful feeding conditional on an indoor-human attempt;
- $K_{s,i,t}$: residual survival associated with intervention-mediated killing.

For an intervention or intervention combination $\mathcal Z$:

$$
(R_{s,i,t},B_{s,i,t},K_{s,i,t})
=
\mathcal E_{\mathcal Z}\!\left(
\text{coverage},
\text{product properties},
\text{product age or decay},
\text{insecticide resistance},
\text{species behaviour};
\boldsymbol\theta_{\mathcal Z}
\right).
$$

A particular implementation may use multiplicative, sequential, competing-risk, or empirically fitted internal relationships. The framework imposes no generic combination rule. Larval source management acts through the habitat/population component, not the $R$, $B$, and $K$ channels.

## 15. Repellency redistributes attempts

The v1 host-choice model assumes repellency redistributes feeding attempts rather than causing otherwise viable attempts to fail.

$$
\widetilde G^{\mathrm{in}}_{s,i,t}
=
R_{s,i,t}G^{\mathrm{in}}_{s,i,t},
$$

$$
\widetilde G^{\mathrm{out}}_{s,i,t}=G^{\mathrm{out}}_{s,i,t},
\qquad
\widetilde G^{\mathrm{animal}}_{s,i,t}=G^{\mathrm{animal}}_{s,i,t}.
$$

The redistributed destination probabilities are:

$$
P^{e,R}_{s,i,t}
=
\frac{\widetilde G^e_{s,i,t}}
{R_{s,i,t}G^{\mathrm{in}}_{s,i,t}+G^{\mathrm{out}}_{s,i,t}+G^{\mathrm{animal}}_{s,i,t}},
$$

for $e\in\{\mathrm{in},\mathrm{out},\mathrm{animal}\}$.

This assumes:

- total attempted feeding rate $a_s^*$ is unchanged by repellency;
- repelled mosquitoes seek an alternative represented host;
- redistribution follows existing host-opportunity weights;
- extra search mortality or delay is absent unless represented by another component.

## 16. Successful human blood-feeding rate

Intervention effects are applied in the following biological order:

$$
\text{attempted feeding rate}
\longrightarrow
\text{repellency and destination redistribution}
\longrightarrow
\text{pathway-specific killing}
\longrightarrow
\text{barrier or feeding prevention}
\longrightarrow
\text{successful feeding}.
$$

Let $K^e_{s,i,t}\in[0,1]$ be residual survival conditional on an attempt through destination pathway $e$, where

$$
e\in\{\mathrm{in},\mathrm{out},\mathrm{animal}\}.
$$

Coverage, product contact, resistance, intervention age, and other determinants of killing are incorporated by the intervention-specific mapping that produces $K^e$. They are not multiplied into the survival equation again.

Let $B^{\mathrm{in}}_{s,i,t}\in[0,1]$ be residual successful feeding conditional on surviving an indoor-human attempt and encountering the relevant barrier. Let $F^{\mathrm{out}}_{s,i,t}\in[0,1]$ be outdoor feeding efficiency, initially defaulting to one.

When killing occurs before feeding, the successful human blood-feeding rate is:

$$
\boxed{
a_{s,i,t}=a^*_{s,i,t}\left[
P^{\mathrm{in},R}_{s,i,t}K^{\mathrm{in}}_{s,i,t}B^{\mathrm{in}}_{s,i,t}
+P^{\mathrm{out},R}_{s,i,t}K^{\mathrm{out}}_{s,i,t}F^{\mathrm{out}}_{s,i,t}
\right].
}
$$

Animal-directed attempts do not contribute to successful human biting, although they may contribute to intervention-mediated mortality. For pathways with no relevant killing effect, set $K^e=1$. For the initial outdoor-feeding implementation:

$$
F^{\mathrm{out}}_{s,i,t}=1.
$$

The equation above represents immediate pre-feed killing. Post-feed or delayed killing reduces subsequent survival but does not prevent the current successful bite. Intervention implementations that distinguish these timings must expose separate pre-feed and post-feed or delayed effects rather than forcing both into one $K^e$.

## 17. Adult survival under interventions

### 17.1 Continuous-rate stationary formulation

Use days as the default public reporting unit, but formulate mortality and attempted feeding in continuous rates so the calculation is invariant to the chosen timestep.

Let:

- $\mu^0_{s,i,t}\geq0$ be the baseline climate-dependent adult mortality hazard per day in the absence of intervention-mediated killing;
- $a^*_{s,i,t}\geq0$ be the attempted-feeding rate per mosquito per day;
- $P^{e,R}_{s,i,t}$ be the post-repellency probability that an attempt is directed through pathway $e$;
- $K^e_{s,i,t}\in[0,1]$ be residual survival conditional on an attempt through pathway $e$.

The attempted-feeding rate through pathway $e$ is:

$$
\lambda^e_{s,i,t}=a^*_{s,i,t}P^{e,R}_{s,i,t}.
$$

Assuming attempts form a stationary Poisson process and pathway-specific killing acts independently per attempt, the intervention-mediated mortality hazard is:

$$
\mu^I_{s,i,t}=a^*_{s,i,t}
\sum_{e\in\{\mathrm{in},\mathrm{out},\mathrm{animal}\}}
P^{e,R}_{s,i,t}\left(1-K^e_{s,i,t}\right).
$$

The total adult mortality hazard is therefore:

$$
\boxed{
\mu_{s,i,t}=\mu^0_{s,i,t}+a^*_{s,i,t}
\sum_e P^{e,R}_{s,i,t}\left(1-K^e_{s,i,t}\right).
}
$$

Survival over an interval of length $\Delta$ days is:

$$
\boxed{
p_{s,i,t}(\Delta)=\exp\left(-\mu_{s,i,t}\Delta\right).
}
$$

Daily survival is obtained with $\Delta=1$. This formulation analytically allows zero, one, or multiple attempts within the interval and therefore does not require converting $a^*$ into a Bernoulli probability of at least one attempt.

When a pathway has no intervention-mediated killing, set $K^e=1$. This permits indoor-human, outdoor-human, and non-human-animal mortality pathways without changing the survival interface.

The barrier term $B$ does not enter the mortality hazard. Repellency and redirection determine the destination of attempts before pathway-specific killing; barrier-mediated feeding prevention acts after killing.

### 17.2 Time-unit invariance

For a timestep of $\Delta$ days, define:

$$
a^*_{\Delta}=a^*_{\mathrm{day}}\Delta,
\qquad
p_{\Delta}=\exp(-\mu_{\mathrm{day}}\Delta),
\qquad
\nu_{\Delta}=\frac{\nu_{\mathrm{day}}}{\Delta}.
$$

Then:

$$
p_{\Delta}^{\nu_{\Delta}}=\exp(-\mu_{\mathrm{day}}\nu_{\mathrm{day}}),
$$

so survival through the EIP is unchanged by the selected time unit. A Garrett-Jones calculation expressed per timestep scales with $\Delta$ and must be converted to the requested reporting unit. The implementation must never mix daily rates, timestep probabilities, and an EIP expressed in different units.

Under stationary conditions, vectorial capacity may equivalently be written using the mortality hazard:

$$
V_{s,i,t}=c_{s,i,t}
\frac{m_{s,i,t}a_{s,i,t}^{2}\exp\left(-\mu_{s,i,t}\nu_{s,i,t}\right)}{\mu_{s,i,t}}.
$$

Here $a_{s,i,t}$ is the successful human blood-feeding rate, while $a^*_{s,i,t}$ enters the encounter-mediated mortality hazard.

### 17.3 Assumptions and limits

The stationary hazard formulation assumes:

- attempted feeding is adequately represented by a stationary Poisson process over the calculation period;
- post-repellency destination probabilities are constant over that period;
- each pathway-specific killing exposure acts independently;
- immediate killing or an effective mortality hazard adequately represents the intervention effect;
- surviving mosquitoes do not change their subsequent behaviour because of previous encounters.

The trajectory-based survival and expected-future-biting formulation should be used when these assumptions are materially violated, including delayed mortality, within-day variation in human presence or intervention use, search delays, partial feeding followed by refeeding, behavioural changes after contact, or explicitly feeding-cycle-dependent effects.

## 18. Multiple species

Total vectorial capacity is:

$$
V_{i,t}=\sum_sV_{s,i,t}.
$$

The implementation must not apply species composition twice. It must distinguish:

- absolute species-specific abundance inputs, whose contributions are calculated directly and summed;
- total abundance plus species fractions, where abundance is allocated before calculating $V_s$;
- single-species-equivalent summaries required by downstream models.

## 19. Vector control impact

For reference scenario 0 and intervention scenario 1:

$$
VCI_{i,t}
=
1-\frac{V^{(1)}_{i,t}}{V^{(0)}_{i,t}},
$$

and:

$$
VCI^{\%}_{i,t}=100VCI_{i,t}.
$$

The reference may be no intervention, status quo, or another named scenario, but must be recorded. The package must define behaviour when reference capacity is zero or effectively zero. Negative VCI values are permitted and indicate increased vectorial capacity relative to the reference.

## 20. Current notation summary

- $L^{\max}_{s,i}$: static, unitless maximum effective larval habitat;
- $\rho_{s,i,u}$: dynamic fraction of that maximum currently available;
- $A_{s,i,u}$: realised effective aquatic habitat;
- $l_{s,i,u}$: aquatic-stage mosquito population state;
- $n_{s,i,u}$: adults per unit maximum effective habitat;
- $\bar n_{s,i,t}$: explicitly aggregated adult quantity for reporting period $t$;
- $m_{s,i,t}$: adult mosquitoes per human;
- $a^*_{s,i,t}$: attempted feeding rate before host selection and protection;
- $a_{s,i,t}$: successful human blood-feeding rate;
- $c_{s,i,t}$: human-to-mosquito infection probability;
- $S^{\mathrm{EIP}}_{s,i,t}$: survival through the realised incubation trajectory;
- $R,B,K^e$: intervention-model outputs for repellency/accessibility, feeding success, and pathway-specific residual survival conditional on an attempt;
- $\mu^0_{s,i,t}$: baseline adult mortality hazard;
- $\mu^I_{s,i,t}$: intervention-mediated adult mortality hazard;
- $\mu_{s,i,t}$: total adult mortality hazard;
- $P^{e,0}$, $P^{e,R}$: temporary notation for pre-intervention and redistributed host-destination probabilities.

## 21. Linked implementation sources to inspect

- `https://github.com/goldingn/mosmicrosim`
- `https://github.com/geryan/va_multispecies_sdm`
- `https://github.com/modd-africa/hackthon2026/pull/1`
- Stopard et al. temperature-dependent HMTP/EIP model and associated code

## 22. Immediate open items

1. Select the final symbol for host-destination fractions.
2. Confirm fine-time-step conventions for accumulated parasite development and any trajectory-based components.
3. Define truncation of the future infectious-biting sum $\Lambda$.
4. Confirm the observation model and calibration strategy connecting HLC to $m_sa_s^*$.
5. Confirm how intervention-specific and combined-intervention mappings produce $R$, $B$, and $K$.
