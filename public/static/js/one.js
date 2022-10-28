window.addEventListener('click', function (e) {
  if (e.target.classList.contains('click-to-expand')) {
    var link_id = e.target.getAttribute('data-link-id');
    var post = null, index = 0
    var path = e.path || (e.composedPath && e.composedPath());
    do {
      // console.log(e);
      post = path[index++]
    } while (!elementIsPost(post));

    var ens = post.nextElementSibling
    var is_expanded = ens && ens.classList.contains('expanded-thumbnail')
    if (is_expanded) {
      if (ens.getAttribute('data-post-id')) {
        // pass
      } else if (ens.getAttribute('data-link-id')) {
        ens.remove()
      }
    } else {
      fetch('/expanded/links/'+link_id)
      .then(async response => {
        var ens = post.nextElementSibling
        var data = null;
        if (response.status !== 200) {
          data = '<'+post.tagName+' class="post expanded-thumbnail alert alert-danger" data-link-id="'+link_id+'">Unexpected error (status code: ' + response.status + ')</'+post.tagName+'>'
        } else {
          data = await response.text()
          data = '<'+post.tagName+' class="post expanded-thumbnail" data-link-id="'+link_id+'">' + data + '</'+post.tagName+'>'
        }
        // literally no need to duplicate if they double clicked
        if (ens && ens.getAttribute('data-link-id') === link_id) {
          return;
        } else {
          var lte = document.createRange().createContextualFragment(data)
          insertAfter(lte, post);
        }
      })
      .catch(error => console.error(error))
    }
  }
})

function elementIsPost(el) {
  console.log(el, el.classList)
  return el && el.classList && el.classList.contains('post') && el.getAttribute('data-post-id')
}
function insertAfter(newNode, existingNode) {
  existingNode.parentNode.insertBefore(newNode, existingNode.nextSibling)
}
