# Iowa Liquor Sales: Ownership Structure & Distribution Continuity

A self-directed analysis using the public Iowa Liquor Sales dataset in BigQuery, centered on two Australian spirits brands — Mr Black and Starward — that took different paths through Diageo's ownership and ended up with different distribution outcomes.

## Why these brands

Mr Black and Starward are two Australian spirits brands I got to know while working at Dan Murphy's. Both had a strong retail presence from what I observed, while also standing out among the relatively small group of Australian spirits brands that have achieved meaningful international reach. This is notable because Australian spirits exports remain relatively small by global standards.

Iowa's public wholesale dataset provides a rare transaction-level view of how these two Australian brands moved through one US distribution market over time. The comparison is particularly useful because both entered Diageo's portfolio through Distill Ventures within months of each other and were distributed in Iowa through the same third-party importer, Park Street Imports. This gives the analysis a relatively consistent commercial setting in which to examine how their distribution paths differed as Diageo's ownership positions evolved.

## Business question

**How do ownership structure and vendor arrangement relate to distribution continuity in Iowa?** More specifically, are the observed patterns consistent with greater distribution control under full ownership than under a minority stake?

## Data

`bigquery-public-data.iowa_liquor_sales.sales` contains wholesale purchase transactions between Iowa retailers and distributors. It is **not consumer retail POS data**, so the analysis interprets the records as retailer purchasing and distribution activity rather than final consumer demand.

Four brands were identified and tracked using regex matching on `item_description`:

| Brand | Role in this analysis | Diageo ownership (as relevant to the Iowa data) | Vendor of record (Iowa) |
|---|---|---|---|
| **Mr Black** | Primary case | Minority stake via Distill Ventures (~10% from Aug 2015, ~20% from 2017); full ownership from **29 Sep 2022** | Park Street Imports (3rd-party importer) |
| **Starward** | Primary case | Minority stake via Distill Ventures (30%, from Dec 2015); divested to founder David Vitale (0%) from **Jan 2026** | Park Street Imports (3rd-party importer) |
| Don Papa | Supporting context | Independently owned; Diageo completed acquisition **10 Mar 2023** | Park Street Imports (3rd-party importer) |
| Mezcal Union | Supporting context | Full ownership of parent company Casa UM (agreed Aug 2021, completed 2022) | Diageo Americas (direct) |

## Method

1. **SQL (BigQuery)** — extracted brand-level transaction records and produced four analytical outputs: monthly retailer purchases by brand; cumulative retailer coverage (the cumulative number of distinct retailers that had purchased each brand at least once); retailer purchase concentration and account ranking; and vendor-level transaction summaries.

   Monthly purchase series were zero-filled **after each brand's first observed transaction**, so months with no recorded retailer purchases appear as `0` rather than being visually connected across missing rows. SQL analysis pipeline: [`01_initial_exploration.sql`](01_initial_exploration.sql).

2. **Power BI** — built a four-page dashboard covering monthly brand purchases, retailer coverage, retailer concentration, and vendor overview. Export: [`Iowa Liquor Market Analysis.pdf`](Iowa%20Liquor%20Market%20Analysis.pdf).

## Findings

### Primary comparison: Mr Black vs Starward

Mr Black and Starward both entered Diageo's portfolio through its Distill Ventures accelerator within months of each other — Mr Black in August 2015, Starward in December 2015 — and both were distributed in Iowa through the same third-party importer, Park Street Imports, for their entire recorded history. From there, Diageo's ownership stake in each brand moved in opposite directions.

**Mr Black — stake deepened over time, then distribution stopped.** Diageo's stake grew from roughly 10% in 2015 to 20% in 2017, before Diageo acquired the remaining shares outright on 29 September 2022. In Iowa, Mr Black's retailer coverage was still expanding through the first seven months of 2023 — already exceeding all of 2022 — when its last recorded transaction occurred on **26 July 2023**, roughly ten months after full acquisition. No further Iowa purchases appear in the dataset after that date.

**Starward — stake stayed flat, then went to zero, and distribution never stopped.** Diageo's 30% stake in Starward was unchanged from December 2015 until January 2026, when Diageo sold it back to founder David Vitale, ending its involvement entirely. Starward's Iowa transaction history runs from **20 July 2021 to 28 April 2026** — continuing through the entire minority-stake period and through the ownership change itself. Its vendor, Park Street Imports, did not change before or after the divestment.

Because the two brands share the same Iowa vendor and entered Diageo's portfolio within months of each other, their different distribution paths are particularly informative. Distribution stopped only for the brand where Diageo's stake crossed into full ownership, while it continued for the brand that remained at a minority stake — and continued after that stake was removed altogether. This pattern is consistent with ownership structure being relevant to distribution continuity, while not ruling out other commercial factors that may also have shaped the outcome.

### Supporting context: Don Papa and Mezcal Union

Two further Diageo-owned brands appear in the dataset and offer additional, weaker context.

**Don Papa** was independently owned until Diageo completed its acquisition on **10 March 2023** — a direct move to full ownership, with no prior minority stake. Its Iowa footprint is small (7 transactions, 42 bottles total) and mostly dormant: after two transactions in December 2019 and February 2020, there's a roughly 33-month gap with no recorded activity until purchasing resumes in late 2022, around when the acquisition was first announced. Of the seven transactions, four (December 2019 – January 2023) occurred while Don Papa was still independently owned; the other three (April, July, and November 2023) fall within the roughly eight months of full Diageo ownership, before purchasing stops entirely after **8 November 2023**. That post-acquisition pattern — a handful of transactions followed by an abrupt stop — echoes Mr Black's shape, just at a much smaller scale, so it offers modest supporting corroboration rather than independent confirmation.

**Mezcal Union** shows what full ownership looks like paired with direct distribution rather than a third-party importer. Diageo agreed to acquire Mezcal Union's parent company, Casa UM, in August 2021, with the acquisition completing in 2022. Mezcal Union's Iowa transactions don't begin until **22 March 2024** — a gap that likely reflects the time needed to integrate a newly-acquired brand into Diageo's direct distribution arm, Diageo Americas, rather than any ambiguity in ownership. Since entering the Iowa market, its retailer coverage has expanded steadily, with 156 transactions and no gap in activity through the dataset's most recent date.

### Why is there no minority-stake / direct-distribution example?

This dataset doesn't include a brand held at minority stake but distributed directly through Diageo Americas — and this may not simply be a small-sample gap. Direct distribution requires a level of operational integration (warehousing, sales teams, logistics) that a minority investor typically wouldn't take on for a brand it doesn't fully own. It's plausible this combination is structurally uncommon, not just unobserved here.

## Limitations

- **Case-study scope.** The analysis focuses on two primary brands, with Don Papa and Mezcal Union used only as supporting context. The observed patterns should therefore be interpreted as comparative case evidence rather than as a general relationship across spirits brands.
- **Ownership is only one possible explanation.** Mr Black and Starward share several useful points of comparison, including their connection to Distill Ventures and their Iowa importer, but they still differ in product category, brand maturity, commercial strategy, and potentially other unobserved factors. The analysis therefore examines whether distribution patterns are *consistent with* differences in ownership structure rather than attributing those patterns to ownership alone.
- **Geographic scope.** Iowa provides a detailed setting in which to observe the distribution histories of the selected Australian brands, but it captures only one part of their broader international distribution networks. The analysis therefore focuses on differences in distribution continuity within Iowa rather than assessing each brand's overall export performance.
