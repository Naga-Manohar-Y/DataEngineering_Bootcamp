# **Fact Data Modeling**

## **Fundamental Properties**
- Represents atomic, indivisible truths that cannot be broken down further.
- Scales **10-100x** more than dimensional data.
- **Immutable** once recorded.
- Requires **strict quality guarantees** with no duplicates or NULLs in critical event fields.
- Must be kept **minimal**, containing only **analysis-essential data**.

---

## **Data Type Requirements**

### **Supported Formats**
- **Basic data types:** Strings, integers, decimals, enumerates.
- **Array of strings:** Supported for handling multiple values.
- **Avoid complex structures like JSON.**

### **Quality Control**
- **No NULL values** in `'what'` and `'when'` event fields.
- **Duplicate Handling Strategies:**
  - **Streaming:** Suitable for moderate datasets requiring immediate consistency.
  - **Microbatch:** Preferred for larger datasets where slight delays are acceptable.

---

## **Modeling Strategies**

### **Context Integration**
Every fact table must capture five essential dimensions:
1. **Who** performed the action.
2. **Where** it occurred.
3. **How** it was done.
4. **What** happened.
5. **When** it took place.

### **Optimization Approaches**
#### **Sampling**
- Effective for **directional metrics and trends**.
- Not suitable for **security issues** or **low probability events**.

#### **Bucketing**
- **Based on the 'who' dimension**.
- Enables **SMB (Sorted Merged Bucket) joins**.
- Reduces **data shuffling** in processing.

---

## **Storage and Retention**

### **Data Volume Management**
- **Dimensional data:** Retain as **legally required**.
- **Fact data:** Typically ranges from **10TB to 100TB**.
- **Optimization Strategies:**
  - Parse and remove **hard-to-understand columns**.
  - Implement **upstream optimization** rather than downstream fixes.

---

## **Best Practices**
- Analyze **duplicate distribution** across time periods.
- Choose appropriate **deduplication timeframes**.
- Implement **shared schemas** for cross-team alignment.
- **Solve data quality issues at the source** rather than applying downstream fixes.

---

This comprehensive approach to **fact data modeling** ensures **data integrity**, **efficient processing**, and maintains **business value and analytical capabilities**.
