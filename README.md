# sBTC-Xynari - Decentralized Prediction Market on Stacks Blockchain

This Clarity smart contract enables the creation and participation in decentralized prediction markets on the Stacks blockchain. Users can stake STX tokens on different outcomes, and winners share the total stake minus a platform fee. The contract supports market creation, staking, partial withdrawals, resolution, refunds, and automated resolution based on block height.

---

## 📜 Features

* 🛠 **Create Prediction Markets**
  Admins can define a market with a question, description, end block, and multiple options.

* 💰 **Stake on Options**
  Users stake STX tokens on their chosen outcome, subject to a minimum stake.

* 🔁 **Partial Stake Withdrawals**
  Users can withdraw part of their stake before the market resolves.

* 🏁 **Market Resolution**
  Admins can resolve markets manually or allow them to auto-resolve based on stake totals.

* 🔄 **Refund for Cancelled Markets**
  If a market is cancelled, participants get full refunds.

* 🎉 **Claim Winnings**
  After resolution, winners claim their rewards proportional to their stake.

* 🔄 **Automatic Resolution**
  Contract can batch process expired unresolved markets based on a stake-majority system.

---

## 📦 Contract Structure

### Constants

* `contract-administrator`: Address of the admin.
* `minimum-stake-amount`: 100,000 µSTX (0.1 STX).
* `platform-fee-percentage`: 2% of total winnings.
* `max-market-id`: Upper bound on the number of markets.

### Maps

* `market-registry`: Stores all market data.
* `participant-stakes`: Tracks individual user stakes per market.
* `market-options`: Holds option labels for each market.

### Data Variables

* `market-counter`: Keeps track of total created markets.

---

## 📘 Function Overview

### ✅ Public Functions

* `create-prediction-market`: Admin creates a new market.
* `place-market-stake`: Users stake STX on an option.
* `withdraw-partial-stake`: Users can withdraw part of their stake before resolution.
* `resolve-prediction-market`: Admin resolves a market by selecting the winning option.
* `cancel-prediction-market`: Admin cancels a market; participants can later claim refunds.
* `claim-rewards-or-refund`: Users claim winnings (if market is resolved) or refund (if cancelled).
* `auto-resolve-markets`: Auto-resolves up to N expired unresolved markets.

### 📖 Read-Only Functions

* `get-market-details`: Fetches data for a specific market.
* `get-market-options-list`: Returns the option list for a market.
* `get-participant-stake-details`: Returns stake details for a participant.
* `get-contract-stx-balance`: Contract's STX balance.

---

## 🚨 Error Codes

| Code | Meaning                 |
| ---- | ----------------------- |
| 100  | Unauthorized            |
| 101  | Market already resolved |
| 102  | Market not resolved     |
| 103  | Invalid stake amount    |
| 104  | Insufficient balance    |
| 105  | Market cancelled        |
| 106  | Invalid option index    |
| 107  | Invalid market ID       |
| 108  | Invalid end block       |
| 109  | Invalid question        |
| 110  | Invalid description     |

---

## 🛡️ Security Notes

* Market creation and resolution are restricted to the `contract-administrator`.
* Users can only withdraw before resolution.
* Winnings are distributed proportionally with platform fees deducted.

---

## 📈 Example Workflow

1. **Admin** calls `create-prediction-market`.
2. **Users** call `place-market-stake` on desired outcomes.
3. Before resolution, users may call `withdraw-partial-stake`.
4. After end block, **admin** or `auto-resolve-markets` resolves the market.
5. **Participants** call `claim-rewards-or-refund`.

---

## 🧪 Testing Recommendations

Test for the following scenarios:

* Invalid market creation (missing description/question).
* Stake below minimum.
* Unauthorized resolution or cancellation.
* Claim after market is resolved.
* Auto-resolve with mixed expired and active markets.

---

## 💡 Future Enhancements

* Voting-based or oracle-fed resolution system.
* Market reputation scores or creator verification.
* UI/UX frontend for easy access.

---
