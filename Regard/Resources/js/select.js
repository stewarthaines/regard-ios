/*global window */
window.addEventListener('load', function() {
//    alert('hi');
    document.addEventListener('selectionchange', function(e) {
        window.location = 'regard://selectionchange';
    });
});
