jQuery.fn.setStatusClass = function(status){
  $(this).removeClass('working').removeClass('success').removeClass('error').addClass(status)
}


function upload_progress_update(upload){
  // console.log( ['Upload:', upload] );
  $('#progress'   ).setStatusClass('working');
  $('#percents'   ).html(upload.percents+'%');
  $('#progressbar').html(upload.received+'/'+upload.size);
}

function upload_progress_complete(upload){
  // console.log( ['Upload complete:', upload] );
  $('#progress'     ).setStatusClass('success');
  $('#upload_status').html('Success!');
  upload_complete = true;
}

function upload_progress_success(upload){
  // console.log( ['Upload success:', upload] );
  $('#progress'     ).setStatusClass('success');
  $('#upload_status').html('Success!');
}

function upload_progress_error(upload){
  // console.log( ['Upload error:', upload] );
  // $('#progress'     ).setStatusClass('error');
  // $('#upload_status').html('Error!');
}

function activate_upload_progress() {
  $('form.upload').uploadProgress({
    dataType:            "json",
    interval:            100,
    progressBar:         "#progressbar",
    progressUrl:         "/progress",
    start:               function(){},
    uploading:           upload_progress_update,
    complete:            upload_progress_complete,
    success:             upload_progress_success,
    error:               upload_progress_error,
    preloadImages:       [],
    jqueryPath:         "./jquery/jquery.js", /* scripts locations, required for safari */
    uploadProgressPath: "./jquery/jquery-upload-progress/jquery.uploadProgress.js",
    timer:               ""
  });
  console.log( 'Upload Progress is go' );
}



// ***************************************************************************
//
//   Load all this stuff
//
$(document).ready(function(){
  activate_upload_progress();
});

// If you need to update the progress bar from a different domain or subdomain, liek if your upload server is different
// from your normal web server, you can try the JSON-P protocol, like this:
// $(function() {
//     $('form').uploadProgress({
//     /* scripts locations for safari */
//     jqueryPath: "../lib/jquery.js",
//     uploadProgressPath: "../jquery.uploadProgress.js",
//     /* function called each time bar is updated */
//     uploading: function(upload) {$('#percents').html(upload.percents+'%');},
//     /* selector or element that will be updated */
//     progressBar: "#progressbar",
//     /* progress reports url in a different domain or subdomain from caller */
//     progressUrl: "uploads.somewhere.com/progress",
//     /* how often will bar be updated */
//     interval: 2000,
//     /* use json-p for cross-domain call */
//     dataType: 'jsonp'
//     });
// });
