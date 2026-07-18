@IsTest
private class OrderLineItemTriggerHandlerTest {
    @TestSetup
    static void setupTestData() {
        insert new List<Product__c>{
            new Product__c(Name = 'Widget A', Available_Stock__c = 100, Price__c = 25),
            new Product__c(Name = 'Widget B', Available_Stock__c = 5, Price__c = 10)
        };
    }

    @IsTest
    static void shouldDeductStockWhenQuantityIsAvailable() {
        Product__c product = [SELECT Id, Available_Stock__c FROM Product__c WHERE Name = 'Widget A' LIMIT 1];
        Order__c orderRecord = new Order__c(Customer_Name__c = 'Jane Doe', Status__c = 'Pending');
        insert orderRecord;

        Test.startTest();
        insert new Order_Line_Item__c(
            Order__c = orderRecord.Id,
            Product__c = product.Id,
            Quantity__c = 10
        );
        Test.stopTest();

        Product__c updatedProduct = [
            SELECT Available_Stock__c
            FROM Product__c
            WHERE Id = :product.Id
        ];

        System.assertEquals(90, updatedProduct.Available_Stock__c, 'Stock should be reduced by ordered quantity.');
    }

    @IsTest
    static void shouldRejectLineItemWhenStockIsInsufficient() {
        Product__c product = [SELECT Id FROM Product__c WHERE Name = 'Widget B' LIMIT 1];
        Order__c orderRecord = new Order__c(Customer_Name__c = 'John Smith', Status__c = 'Pending');
        insert orderRecord;

        Order_Line_Item__c lineItem = new Order_Line_Item__c(
            Order__c = orderRecord.Id,
            Product__c = product.Id,
            Quantity__c = 10
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(lineItem, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(), 'Insert should fail when stock is insufficient.');
        System.assert(result.getErrors()[0].getMessage().contains('Insufficient stock'), 'Expected stock error message.');
    }

    @IsTest
    static void shouldHandleBulkInsertAcrossMultipleProducts() {
        List<Product__c> products = [SELECT Id, Available_Stock__c FROM Product__c ORDER BY Name];
        Order__c orderRecord = new Order__c(Customer_Name__c = 'Bulk Buyer', Status__c = 'Pending');
        insert orderRecord;

        List<Order_Line_Item__c> lineItems = new List<Order_Line_Item__c>{
            new Order_Line_Item__c(Order__c = orderRecord.Id, Product__c = products[0].Id, Quantity__c = 15),
            new Order_Line_Item__c(Order__c = orderRecord.Id, Product__c = products[0].Id, Quantity__c = 5),
            new Order_Line_Item__c(Order__c = orderRecord.Id, Product__c = products[1].Id, Quantity__c = 2)
        };

        Test.startTest();
        insert lineItems;
        Test.stopTest();

        Map<Id, Product__c> updatedProducts = new Map<Id, Product__c>([
            SELECT Available_Stock__c
            FROM Product__c
            WHERE Id IN :products
        ]);

        System.assertEquals(80, updatedProducts.get(products[0].Id).Available_Stock__c);
        System.assertEquals(3, updatedProducts.get(products[1].Id).Available_Stock__c);
    }
}
