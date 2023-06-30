import { LightningElement, track, wire, api } from 'lwc';
import getContacts from '@salesforce/apex/productTableController.getContacts';
import getContactFields from '@salesforce/apex/productTableController.getContactFields';
import getSyncProductFields from '@salesforce/apex/productTableController.getSyncProducts';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class ForcastTable extends LightningElement {
    @api recordId;
    @track columns = [
        {
            label: 'Product', fieldName: 'ProductURL', type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'Name'
                }
            }
        },
        { label: 'Description', fieldName: 'Description' },
        { label: 'Existing Contract Value', fieldName: 'TotalPrice' },
        { label: 'Best Case Delta', fieldName: 'Best_Case_Delta__c' },
        { label: 'Promise Case Delta', fieldName: 'Promise_Case_Delta__c' },
        { label: 'Worst Case Delta', fieldName: 'Worst_Case_Delta__c' },

        { label: 'Total Best Case Delta', fieldName: 'Total_Best_Case_value__c' },
        { label: 'Total Promise Case Delta', fieldName: 'Total_Promise_Case_value__c' },
        { label: 'Total Worst Case Delta', fieldName: 'Total_Worst_Case_value__c' },

    ];

    @track selected = ['Id', 'Name', 'ProductCode', 'Description'];
    @track fetchedProducts = [];
    @track preparedProducts = [];
    @track displayProducts = [];
    @track refreshcopy = [];
    @track error;
    @track setTimer = 1000;//1 s delay
    @track loader=false;
    error;
    subscription = {};
    CHANNEL_NAME = '/event/RefreshProductPassive__e';
    timeoutId;
    
    //Connected Callback Function
    connectedCallback(){
        subscribe(this.CHANNEL_NAME, -1, this.handleEvent).then(response => {
            console.log('Successfully subscribed to channel');
            this.subscription = response;
        });
        onError(error => {
            console.error('Received error from server: ', error);
        });
    }
    //Handle Record Refresh Action
    handleEvent = event => {
        const refreshRecordEvent = event.data.payload;
        if (refreshRecordEvent.recordId__c === this.recordId) {
            return this.onChangeHandler();
        }
    }
    disconnectedCallback = () => {
        unsubscribe(this.subscription, () => {
            console.log('Successfully unsubscribed');
        });
    }

    @wire(getContactFields) wiredContactFields;
    @wire(getContacts, { selectedFields: '$selected', recordId: '$recordId' })
    wiredContacts(result) {
        this.refreshcopy = result;
        if (result.data) {
            this.error = undefined;
            this.fetchedProducts = result.data;
            console.log('Initial Products List', this.fetchedProducts);
            if (this.fetchedProducts) {
                this.productsStore(this.fetchedProducts);  
            }
        } else if (result.error) {
            this.error = result.error;
            this.fetchedProducts = [];
            console.log('error found>>>', this.error);
        }

    }
    //Refresh the result 
    onChangeHandler() {
        this.loader=true;
        clearTimeout(this.timeoutId); // no-op if invalid id
        this.timeoutId = setTimeout(this.FetchOppItems.bind(this), 3000); // Adjust as necessary
       
    }
    FetchOppItems(){
        this.displayProducts = [];
        this.preparedProducts = [];
        this.fetchedProducts = [];
        getSyncProductFields({ recordId: this.recordId })
            .then(data => {
                console.log('Products Refresh>>>', data);
                if (data) {
                    this.fetchedProducts = data;
                    if (this.fetchedProducts) {
                        this.productsStore(this.fetchedProducts);  
                        this.loader=false;
                    }
                } else {
                    console.log('Error Found');
                }
            })

    }
    //Prepares the Products table data
    productsStore(fetchedProducts){
        fetchedProducts.forEach(item => {
            let preparedAdd = {};
            preparedAdd.Id = item.Id;
            preparedAdd.ProductCode = item.Product2.ProductCode;
            preparedAdd.Name = item.Product2.Name;

            preparedAdd.Description = item.Description;
            preparedAdd.ListPrice = item.ListPrice;
            //Number Metrics
            preparedAdd.Best_Case_Delta__c = item.Best_Case_Delta__c;
            preparedAdd.Promise_Case_Delta__c = item.Promise_Case_Delta__c;
            preparedAdd.Worst_Case_Delta__c = item.Worst_Case_Delta__c;
            //Formula Metrics
            preparedAdd.Total_Best_Case_value__c = item.Total_Best_Case_value__c;
            preparedAdd.Total_Promise_Case_value__c = item.Total_Promise_Case_value__c;
            preparedAdd.Total_Worst_Case_value__c = item.Total_Worst_Case_value__c;

            preparedAdd.UnitPrice = item.UnitPrice;
            preparedAdd.Quantity = item.Quantity;
            preparedAdd.TotalPrice = item.ListPrice + item.UnitPrice;
            preparedAdd.ProductURL = '/lightning/r/OpportunityLineItem/' + item.Id + '/view';
            //Push the Products lane to the preparedProducts array
            this.preparedProducts.push(preparedAdd);
        });
        //Assign to the Display Array
        this.displayProducts = this.preparedProducts;
    }
}