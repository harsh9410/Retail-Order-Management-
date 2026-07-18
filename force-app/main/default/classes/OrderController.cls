public with sharing class OrderController {
    @AuraEnabled(cacheable=true)
    public static List<Order__c> getPendingOrders() {
        return [
            SELECT Id, Name, Customer_Name__c, Total_Amount__c, Status__c, CreatedDate
            FROM Order__c
            WHERE Status__c = 'Pending'
            WITH SECURITY_ENFORCEMENT
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }
}
