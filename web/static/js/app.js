import {Socket, LongPoller} from "phoenix"

class App {

  static init(){
    var $status    = $("#status")
    var $messages  = $("#messages")
    var $input     = $("#message-input")
    var $userid    = $("#userid")
    var $username  = $("#username")
    var $usersub   = $("#usersub")
    var $adi       = $("#adi")
    var $csrf      = $("#csrf")

    let socket = new Socket("/socket", {
      logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
    })
    socket.connect({user_id: $userid.val()})
    socket.onOpen( ev => console.log("OPEN", ev) )
    socket.onError( ev => console.log("ERROR", ev) )
    socket.onClose( ev => console.log("CLOSE", ev))

    var chan = socket.channel("rooms:lobby", {csrf: $csrf.val()})
    chan.join().receive("ignore", () => console.log("auth error"))
               .receive("ok", () => console.log("join ok"))
               .after(10000, () => console.log("Connection interruption"))
    chan.onError(e => console.log("something went wrong", e))
    chan.onClose(e => console.log("channel closed", e))

    $input.off("keypress").on("keypress", e => {
      if (e.keyCode == 13) {
        if ($.trim($input.val()).length > 0) {
          chan.push("new:msg", {csrf: $csrf.val(), userid: $userid.val(), user: $username.val(), sub: $usersub.val(), adi: $adi.val(), body: $input.val()})
          $input.val("");
        }
      }
    })

    chan.on("history:msgs", msgs => {
      for (var i = 0; msgs.history.length > i; i++) {
        var tempLogs = decodeURIComponent(escape(window.atob( msgs.history[i] )))
        var logs = tempLogs.replace(/(\~)+/g, "~");
        var msg = {user : logs.split("~")[1],
                  sub : logs.split("~")[2], 
                  adi : logs.split("~")[3],
                  body : logs.split("~")[4],
                  role: logs.split("~")[5]
        }
        $messages.append(this.messageTemplate(msg))
      }
      scrollTo(0, document.body.scrollHeight)
    })

    chan.on("new:msg", msg => {
      $messages.append(this.messageTemplate(msg))
      if (document.body.scrollHeight - window.pageYOffset < 1000 ){
        scrollTo(0, document.body.scrollHeight)
      }
    })

    $(document).on('dblclick','.name',function(){
      if ($adi[0].value == "true"){
        if($(this).next().css("display") == "none"){
          $(this).next().css("display", "inline-block"); 
        }else{
          $(this).next().css("display", "none"); 
        }
      }
    });
  }

  static sanitize(html){ return $("<div/>").text(html).html() }

  static messageTemplate(msg){
    let username = this.sanitize(msg.user || "anonymous")
    let usersub  = this.sanitize(msg.sub)
    let adi      = this.sanitize(msg.adi || "false")
    let body     = this.sanitize(msg.body)
    let role      = this.sanitize(msg.role)
    if (username == "SYSTEM") {
      return(`<p class="text-center"><span class="time">${moment(body * 1000).fromNow()}</span></p>`)
    }
    if (adi == "true") {
      return(`<p class="admin"><span class="name">${username}</span><span>${body}</span></p>`)
    } else if (role != "") {
      return(`<p class="${role}"><span class="name">${username}</span><span>${usersub}</span><span>${body}</span></p>`)
    } else{
      return(`<p class="normal"><span class="name">${username}</span><span>${usersub}</span><span>${body}</span></p>`)
    }
  }
}

$( () => App.init() )
moment.locale('zh-cn')
export default App
