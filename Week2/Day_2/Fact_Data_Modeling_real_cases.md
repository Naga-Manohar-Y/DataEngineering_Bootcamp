# **Real-World Data Engineering Case Studies**

## **Netflix Network Logs Challenge**

### **Problem and Scale**
- **Processing 2PB of daily network traffic data** to understand **microservice communications**.
- Critical for **security analysis** of inter-app communications.
- Challenge of handling both **IPv4 (32-bit) and IPv6 (128-bit) addresses**.

### **Solution Implementation**
#### **IPv4 Handling**
- Used **IP addresses as app identifiers** in a smaller database.
- Applied **broadcast joins** for efficient querying.

#### **IPv6 Handling**
- Implemented **sidecar proxy** for direct app logging.

### **Key Learning**
- Solve **data quality issues at the source** rather than optimizing downstream.

---

## **Airbnb Pricing Conformance**

### **Challenge**
- Multiple teams (**Pricing and Online Service**) using **different frameworks** (**Ruby, Scala**).
- Need for **consistent pricing definitions** across platforms.
- Risk of **misaligned pricing understanding** between teams.

### **Solution Architecture**
- Implemented **shared schema** as a middle layer.
- Used **Thrift Schema** for **language-agnostic definitions**.
- Automatic **push notifications** when schema updates occur.
- Ensures **pricing conformance** across all systems.

---

## **Data Sampling Strategy**

### **Implementation Approach**
- Effective for **directional metrics and trends**.
- **Validated by the Law of Large Numbers**.
- Provides **efficient analysis** of large-scale data.

### **Limitations**
Not suitable for:
1. **Security-related issues**
2. **Low probability events**
3. **Specific row-level data requirements**

---

## **Key Takeaways**
- **Real-world constraints** shape architectural decisions.
- Prioritize **upstream data quality** over downstream fixes.
- Optimize processing while **maintaining business requirements**.
