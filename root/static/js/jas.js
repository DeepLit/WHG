document.onmouseup = mouse_up;
var prev_selected = '';

function mouse_up(){
    if(document.getElementById("JAS_toggle").checked==true){
        var txt = '';
        var newWindow;

        if (window.getSelection){
                txt = window.getSelection();
        }
        else if (document.getSelection){
                txt = document.getSelection();
        }
        else if (document.selection){
                txt = document.selection.createRange().text;
        }
        else return;

        if(txt != "" && txt.toString().length > 2 && txt.toString().length < 101 && prev_selected != txt.toString()){
                prev_selected = txt.toString();
                newWindow = window.open('http://www.chemspider.com/Search.aspx?q='+txt.toString());     
        }
   }
}
