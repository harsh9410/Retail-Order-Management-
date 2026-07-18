@IsTest
private class OrderControllerTest {
    @TestSetup
    static void setupTestData() {
        insert new List<Order__c>{
            new Order__c(Customer_Name__c = 'Pending Customer', Status__c = 'Pending'),
            new Order__c(Customer_Name__c = 'Shipped Customer', Status__c = 'Shipped'),
            new Order__c(Customer_Name__c = 'Another Pending Customer', Status__c = 'Pending')
        };
    }

    @IsTest
    static void shouldReturnOnlyPendingOrders() {
        Test.startTest();
        List<Order__c> pendingOrders = OrderController.getPendingOrders();
        Test.stopTest();

        System.assertEquals(2, pendingOrders.size(), 'Only pending orders should be returned.');
        for (Order__c orderRecord : pendingOrders) {
            System.assertEquals('Pending', orderRecord.Status__c);
        }
    }
}
