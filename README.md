# RideChain

RideChain is a decentralized rideshare platform that challenges the status quo of centralized mobility services by introducing a transparent, trustless, and cost-efficient alternative. Leveraging blockchain smart contracts, AI-driven driver scoring, and thorough collateral-based incentives, RideChain empowers riders and drivers to interact directly—with higher earnings for drivers, lower costs for riders, and no central authority.

The system centers around three core innovations:
- A fully decentralized smart contract-based ride request and fulfillment protocol.
- A collateral based reputation system to incentivize drivers to behave correctly if they want to withdraw funds 
- AI-enhanced reputation scoring based on real ride data and user reviews and feedback.

Diagrams can be found in the Diagrams folder to see sequence and component diagrams. 

---

## Demo/Stakeholders

The RideChain platform involves two primary end-user groups—Drivers and Riders—each playing a critical role in the decentralized rideshare ecosystem. The project demo will showcase both perspectives, highlighting the registration process, smart contract interactions, and the AI-enhanced rating system in action.

Driver:
Drivers are independent service providers who wish to earn income by offering transportation services through the RideChain platform. To ensure trust and safety, drivers must first register and submit a hefty collateral sum which is securely stored on the driver smart contract. Once registered, drivers can view open ride requests in their area and propose custom pricing for each ride. The smart contract handles all interactions transparently, and payment is automatically released upon ride completion, as verified by a mobile oracle. Additionally, each driver's score is continuously updated by an AI model trained on real-world Uber ride data, factoring in feedback and performance to promote high-quality service providers. Only after the driver score hits a certain threshold and they have completed a successful number of rides, then they are able to withdraw funds from their account. This deters malicious actors from joining the system as they would have to put in a large amount of financial assets and obtain positive reviews.   

Rider:
Riders are individuals looking for reliable and cost-effective transportation. After registering on the platform, riders can submit a ride request by specifying their start and end locations, preferred vehicle size, and number of passengers. Once the request is live, nearby drivers respond with price offers. Riders can then browse these proposals and select the one that best matches their preferences in terms of cost and driver score. Throughout the ride, the mobile oracle tracks trip progress, ensuring that pickup and drop-off are completed as promised. Upon successful completion, payment is processed via smart contract and the rider may leave a review, contributing to the driver's AI-updated reputation.

Together, drivers and riders create a trustless, efficient, and incentive-aligned system. The demo will walk through the end-to-end user flows for both stakeholders, including smart contract registrations, offer selection, ride tracking, payment disbursement, and AI-based score updates—all without reliance on a centralized authority.

---

## Project Outcomes

Decentralized Rideshare Protocol: The primary outcome of this project is a fully decentralized rideshare platform that removes reliance on centralized intermediaries like Uber and Lyft. By utilizing blockchain-based smart contracts, RideChain ensures transparent, tamper-proof coordination between riders and drivers, reducing platform fees and redistributing value more fairly.

Collateral-Based incentives: By using such an economic system, drivers have incentive to build reputation and complete rides in a acceptable manner if they want to be able to access their funds. The inverse also stands: if a driver receives far too many negative reviews from different riders, then the driver funds can be frozen so no funds can be withdrawn. 

AI-Driven Reputation System: A key innovation of RideChain is its integration of an AI model trained on real-world rideshare data to dynamically evaluate and update driver scores. This system enhances service quality by prioritizing reliable drivers, and ensures reputation is earned fairly through objective performance data and rider reviews. 

Smart Oracle-Based Ride Verification: The mobile oracle acts as a decentralized verifier, confirming the location-based completion of rides. This feature ensures riders only pay for completed services and drivers are automatically compensated upon ride fulfillment, all without a human middleman.

Transparent Marketplace for Rides: By enabling drivers to set their own pricing and allowing riders to choose from multiple offers, the system creates a competitive and efficient marketplace. This model supports better resource allocation and price discovery while maintaining trust through verified reputations and transparent transactions.

Increased Accessibility and Equity: RideChain empowers both riders and drivers by eliminating platform-driven gatekeeping and algorithmic opacity. It enables participation in a decentralized ecosystem where users maintain control over their data, payments, and service terms.

In conclusion, RideChain delivers a secure, fair, and scalable alternative to centralized rideshare apps. It is expected to foster a transparent and user-first mobility economy—one where privacy, trust, and choice are fundamental pillars of the experience.

---

