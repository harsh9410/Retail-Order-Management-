public with sharing class OrderLineItemTriggerHandler {
    public static void handleBeforeInsert(List<Order_Line_Item__c> newLineItems) {
        if (newLineItems == null || newLineItems.isEmpty()) {
            return;
        }

        AggregateResult aggregateResult = aggregateQuantitiesByProduct(newLineItems);
        if (aggregateResult.quantityByProductId.isEmpty()) {
            return;
        }

        Map<Id, Product__c> productsById = new Map<Id, Product__c>([
            SELECT Id, Name, Available_Stock__c
            FROM Product__c
            WHERE Id IN :aggregateResult.quantityByProductId.keySet()
            FOR UPDATE
        ]);

        Boolean hasValidationErrors = aggregateResult.hasValidationErrors
            || validateStockAvailability(
                newLineItems,
                aggregateResult.quantityByProductId,
                productsById
            );

        if (!hasValidationErrors) {
            deductStock(aggregateResult.quantityByProductId, productsById);
        }
    }

    private class AggregateResult {
        Map<Id, Decimal> quantityByProductId = new Map<Id, Decimal>();
        Boolean hasValidationErrors = false;
    }

    private static AggregateResult aggregateQuantitiesByProduct(List<Order_Line_Item__c> lineItems) {
        AggregateResult result = new AggregateResult();

        for (Order_Line_Item__c lineItem : lineItems) {
            if (lineItem.Product__c == null) {
                result.hasValidationErrors = true;
                lineItem.addError('Product is required before stock can be reserved.');
                continue;
            }

            if (lineItem.Quantity__c == null || lineItem.Quantity__c <= 0) {
                result.hasValidationErrors = true;
                lineItem.addError('Quantity must be greater than zero.');
                continue;
            }

            Decimal existingQuantity = result.quantityByProductId.containsKey(lineItem.Product__c)
                ? result.quantityByProductId.get(lineItem.Product__c)
                : 0;
            result.quantityByProductId.put(lineItem.Product__c, existingQuantity + lineItem.Quantity__c);
        }

        return result;
    }

    private static Boolean validateStockAvailability(
        List<Order_Line_Item__c> lineItems,
        Map<Id, Decimal> quantityByProductId,
        Map<Id, Product__c> productsById
    ) {
        Boolean hasValidationErrors = false;

        for (Order_Line_Item__c lineItem : lineItems) {
            if (lineItem.Product__c == null || lineItem.Quantity__c == null || lineItem.Quantity__c <= 0) {
                continue;
            }

            Product__c product = productsById.get(lineItem.Product__c);
            if (product == null) {
                hasValidationErrors = true;
                lineItem.addError('The selected product could not be found.');
                continue;
            }

            Decimal availableStock = product.Available_Stock__c == null ? 0 : product.Available_Stock__c;
            Decimal requestedQuantity = quantityByProductId.get(lineItem.Product__c);

            if (requestedQuantity > availableStock) {
                hasValidationErrors = true;
                lineItem.addError(
                    'Insufficient stock for ' +
                    product.Name +
                    '. Available: ' +
                    availableStock.intValue() +
                    ', Requested in this transaction: ' +
                    requestedQuantity.intValue() +
                    '.'
                );
            }
        }

        return hasValidationErrors;
    }

    private static void deductStock(
        Map<Id, Decimal> quantityByProductId,
        Map<Id, Product__c> productsById
    ) {
        List<Product__c> productsToUpdate = new List<Product__c>();

        for (Id productId : quantityByProductId.keySet()) {
            Product__c product = productsById.get(productId);
            if (product == null) {
                continue;
            }

            Decimal availableStock = product.Available_Stock__c == null ? 0 : product.Available_Stock__c;
            product.Available_Stock__c = availableStock - quantityByProductId.get(productId);
            productsToUpdate.add(product);
        }

        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate;
        }
    }
}
