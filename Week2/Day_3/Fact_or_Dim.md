# **Understanding Facts vs. Dimensions in Data Modeling**

## **Distinction Between Facts and Dimensions**
Facts and dimensions exist in a **complex relationship**, where some data points can function as both, depending on context. The key distinction lies in whether the data **captures a state (dimension)** or **records an event (fact)**.

---

## **State vs. Event**
| **Aspect**       | **Dimensions (State)**           | **Facts (Event)**             |
|-----------------|--------------------------------|------------------------------|
| **Definition**   | Captures system **state** (snapshots) | Records events **as they occur** in time |
| **Nature**       | Static or slowly changing      | Dynamic and transactional |
| **Usage Context** | Provides **descriptive context** | Used for **analytics and aggregations** |

---

## **Real-World Examples**
### **Airbnb Use Cases**
1. **User Activity Status**
   - `dim_is_active`: **Dimension** when capturing the **current state** of a user (e.g., active/inactive).
   - `fact_user_activity`: **Fact** when logging **individual login events**.

2. **Pricing Information**
   - **Dimension**: Captures the **current listing price** as a state attribute.
   - **Fact**: Logs **price change events** when a host updates settings.

---

## **Common Characteristics**
| **Facts**  | **Dimensions** |
|------------|--------------|
| Used in **aggregations** (`SUM`, `AVG`) | Used in **GROUP BY** clauses |
| **Event-driven** logging | **State-driven** snapshots |
| Can be **transformed into dimensions** via aggregation | Provide **context to facts** |
| Generally **higher cardinality** | Variable cardinality range |

---

## **Practical Guidelines**
### **Identifying Dimensions**
✅ **Represents nouns** (customer, product, location)  
✅ Frequently appears in **GROUP BY** clauses  
✅ Provides **descriptive context**  
✅ Derived from **state snapshots**  

### **Identifying Facts**
✅ **Represents verbs** (sales, logins, messages)  
✅ Frequently used in **aggregate functions**  
✅ Derived from **logs or events**  
✅ Can be transformed into **dimensions through aggregation**  

---

## **Key Takeaway**
The classification of data as **facts or dimensions** is often determined more by **how the data is used** rather than its inherent structure. Understanding this distinction helps in designing **efficient, scalable data models** that align with business needs. 🚀
