# ⚡ Energy Transition Metals Tracker

> 🌱 **Blockchain traceability for ethically sourced critical minerals** ⛏️

A Clarity smart contract that provides immutable tracking of energy transition metals (Lithium, Cobalt, Rare Earths) from mining to market, ensuring ethical sourcing and trade compliance.

## 🎯 Features

- 📋 **Immutable Mining Records** - Track minerals from extraction to end use
- 🏆 **Ethical Certifications** - Issue and verify ethical sourcing certificates  
- ⚖️ **Trade Compliance** - Smart contract enforcement of compliance rules
- 🔗 **Supply Chain Tracking** - Complete visibility across the supply chain
- 🌍 **Carbon Footprint Monitoring** - Track environmental impact

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation
```bash
git clone <repository-url>
cd Energy-Transition-Metals--Lithium--Cobalt--Rare-Earths-
clarinet console
```

## 📖 Usage

### 1. 🏭 Register Mineral Batch
```clarity
(contract-call? .energy-transition-metals register-mineral-batch 
  "lithium" 
  u1000 
  "Australian Mine Co" 
  u1000000 
  u85 
  u50)
```

### 2. 🏅 Register Certification Authority
```clarity
(contract-call? .energy-transition-metals register-certifier 
  'SP1...CERTIFIER 
  "Ethical Mining Institute" 
  (list "fair-trade" "conflict-free" "environmental"))
```

### 3. ✅ Issue Certification
```clarity
(contract-call? .energy-transition-metals issue-certification 
  u1 
  "fair-trade" 
  u2000000 
  0x1234...)
```

### 4. 📦 Transfer Ownership
```clarity
(contract-call? .energy-transition-metals transfer-batch 
  u1 
  'SP2...NEWOWNER 
  "Processing Facility A" 
  "refined")
```

### 5. 📊 Update Status
```clarity
(contract-call? .energy-transition-metals update-batch-status 
  u1 
  "processed" 
  "Manufacturing Plant" 
  true 
  (some 25) 
  (some u60))
```

## 🔍 Read-Only Functions

### Get Batch Information
```clarity
(contract-call? .energy-transition-metals get-batch u1)
```

### Check Compliance
```clarity
(contract-call? .energy-transition-metals is-batch-compliant u1)
```

### View Supply Chain
```clarity
(contract-call? .energy-transition-metals get-supply-chain-record u1)
```

### Get Certification Count
```clarity
(contract-call? .energy-transition-metals get-certification-count u1)
```
Returns the number of certifications for a batch.

## ⚖️ Compliance Rules

Set trade compliance rules for different metal types:

```clarity
(contract-call? .energy-transition-metals set-trade-compliance-rule 
  "lithium" 
  u80 
  (list "fair-trade" "conflict-free") 
  u100 
  (list "restricted-country"))
```

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

## 📁 Project Structure

```
├── contracts/
│   └── Energy-Transition-Metals--Lithium--Cobalt--Rare-Earths.clar
├── tests/
├── settings/
├── Clarinet.toml
└── README.md
```

## 🌐 Key Concepts

- **🔗 Batch ID**: Unique identifier for each mineral batch
- **🏅 Certification**: Ethical sourcing certificates with expiry dates
- **📍 Supply Chain Record**: Complete history of batch movement and handling
- **⚖️ Compliance Score**: Numerical rating for ethical sourcing (0-100)
- **🌱 Carbon Footprint**: Environmental impact measurement

## 🛡️ Security Features

- ✅ Owner-only administrative functions
- 🔐 Authorization checks for certifiers
- 📝 Immutable audit trails
- ⚖️ Compliance validation before transfers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests with `clarinet test`
4. Submit a pull request

## 📜 License

This project is open source and available under the MIT License.

## 🗂️ Batch Retirement Feature

This new feature allows the current owner of a mineral batch to retire it, marking the end of its lifecycle. This enhances traceability by recording the retirement event in the supply chain records and updating the batch status to "retired".

### Usage
```clarity
(contract-call? .energy-transition-metals retire-batch
  u1
  "Disposal Facility")
```

This function ensures that only the current owner can retire the batch and prevents retiring already retired batches.

---

*Made with 💚 for sustainable mining practices*
