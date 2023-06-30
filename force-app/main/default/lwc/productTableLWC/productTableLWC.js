import { LightningElement, track, wire,api } from 'lwc';
import getContacts from '@salesforce/apex/productTableController.getContacts';
import getContactFields from '@salesforce/apex/productTableController.getContactFields';
import getFieldTypes from '@salesforce/apex/productTableController.getFieldTypes';

export default class ProductTableLWC extends LightningElement {
    
    @api recordId;
   
    @track columns = [
        {label: 'Product', fieldName: 'ProductURL', type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'Name'
                }
            }
        },
        {label:'ProductCode', fieldName:'ProductCode'},
        {label:'Description', fieldName:'Description'},
        {label:'Quantity', fieldName:'Quantity'},
        {label:'ListPrice', fieldName:'ListPrice'},
        {label:'SalesPrice', fieldName:'UnitPrice'},
        {label:'TotalPrice', fieldName:'TotalPrice'}
    ];
    @track selected = ['Id', 'Name','ProductCode','Description'];
    @track fetchedProducts=[];
    @track preparedProducts=[];
    @track displayProducts=[];
    connectedCallback(){
        console.log('RecordDetak apge');
        console.log('api recordid>>>' , this.recordId);
    }
    
    @wire(getContactFields) wiredContactFields;
    @wire(getContacts, { selectedFields: '$selected' , recordId:'$recordId' })
    wiredContacts({ error, data }) {
        if (data) {
            this.fetchedProducts = data;
            console.log('Products>>>' , this.fetchedProducts);
            if(this.fetchedProducts){
               
                this.fetchedProducts.forEach(item => {
                  
                    let preparedAdd = {};
                    preparedAdd.Id=item.Id;
                    preparedAdd.ProductCode=item.Product2.ProductCode;
                    preparedAdd.Name=item.Product2.Name;
                   
                    preparedAdd.Description=item.Description;
                    preparedAdd.ListPrice=item.ListPrice;
                    preparedAdd.UnitPrice=item.UnitPrice;
                    preparedAdd.Quantity=item.Quantity;
                    preparedAdd.TotalPrice=item.ListPrice+item.UnitPrice;
                    preparedAdd.ProductURL='/lightning/r/OpportunityLineItem/' +item.Id +'/view';
                    //Push the Products lane
                    this.preparedProducts.push(preparedAdd);
                });
                //Assign to the Display Array
                this.displayProducts=this.preparedProducts;
                console.log(this.preparedProducts);
            }
        } else if (error) {
            console.log(error);
        }
    }
    //Dev Test
      //Dev Test  //Dev Test  //Dev Test  //Dev Test
    handleSelectedFields(event) {
        //clean the array
        this.selected.splice(0, this.selected.length);
        this.fetchedProducts = [];
        this.columns = [];

        for (var option of this.template.querySelector('select').options) {
            if (option.selected) {
                this.selected.push(option.value);
            }
        }

        getContacts({ selectedFields: this.selected })
            .then(result => {
                this.fetchedProducts = result;
                this.handleFetchFieldTypes();
            })
            .catch(error => {
                console.log(error);
            });
    }
    
    handleSelectedFieldsNew(event) {
        //clean the array
        this.selected.splice(0, this.selected.length);
        this.fetchedProducts = [];
        this.columns = [];

        for (var option of this.template.querySelector('select').options) {
            if (option.selected) {
                this.selected.push(option.value);
            }
        }

        getContacts({ selectedFields: this.selected })
            .then(result => {
                this.fetchedProducts = result;
                this.handleFetchFieldTypes();
            })
            .catch(error => {
                console.log(error);
            });
    }

    handleFetchFieldTypes() {
        getFieldTypes({ selectedFields: this.selected })
            .then(result => {
                this.columns = this.selected.map(field => {
                    const dType = result[field];
                    if (dType === 'STRING' || dType === 'ID') {
                        return { label: field, fieldName: field };
                    } else if (dType === 'DATE') {
                        return { label: field, fieldName: field, type: 'date' };
                    } else if (dType === 'DATETIME') {
                        return {
                            label: field,
                            fieldName: field,
                            type: 'datetime'
                        };
                    } else if (dType === 'Integer') {
                        return {
                            label: field,
                            fieldName: field,
                            type: 'Integer'
                        };
                    } else if (dType === 'BOOLEAN') {
                        return {
                            label: field, label: 'Name', fieldName: 'AccountURL', type: 'url',
 
                            fieldName: field,
                            type: 'text'
                        };
                    } else {
                        return { label: field, fieldName: field };
                    }
                });
            })
            .catch(error => {
                console.log(error);
            });
    }
}