import { LightningElement, wire } from 'lwc';
import getPendingOrders from '@salesforce/apex/OrderController.getPendingOrders';

const COLUMNS = [
    {
        label: 'Order Number',
        fieldName: 'orderUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    },
    { label: 'Customer Name', fieldName: 'Customer_Name__c', type: 'text' },
    {
        label: 'Total Amount',
        fieldName: 'Total_Amount__c',
        type: 'currency',
        typeAttributes: { currencyCode: 'USD' }
    },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    {
        label: 'Created Date',
        fieldName: 'CreatedDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    }
];

export default class PendingOrders extends LightningElement {
    columns = COLUMNS;
    orders = [];
    error;
    isLoading = true;

    @wire(getPendingOrders)
    wiredPendingOrders({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.orders = data.map((order) => ({
                ...order,
                orderUrl: `/lightning/r/Order__c/${order.Id}/view`
            }));
            this.error = undefined;
        } else if (error) {
            this.orders = [];
            this.error = this.reduceErrors(error);
        }
    }

    get hasOrders() {
        return !this.isLoading && !this.error && this.orders.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.error && this.orders.length === 0;
    }

    reduceErrors(error) {
        if (Array.isArray(error.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        if (typeof error.body?.message === 'string') {
            return error.body.message;
        }
        return 'An unexpected error occurred while loading pending orders.';
    }
}
