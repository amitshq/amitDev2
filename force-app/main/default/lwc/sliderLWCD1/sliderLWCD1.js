import { LightningElement } from 'lwc';

export default class SliderLWCD1 extends LightningElement {
    
		 val = 50;
		
         fireEvent(recordId, apiName) {
         this.dispatchEvent(
             new CustomEvent('itemspointed', {
                 cancelable : true,
                 bubbles : true,
                 composed : true,
                 detail : {
                     recId : this.val
                 }
             })
         );
     }
     
}