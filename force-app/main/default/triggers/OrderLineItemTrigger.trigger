trigger OrderLineItemTrigger on Order_Line_Item__c (before insert) {
    OrderLineItemTriggerHandler.handleBeforeInsert(Trigger.new);
}
