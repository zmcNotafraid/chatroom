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
    var $tag       = $("#tag")
    var $csrf      = $("#csrf")
    var $role      = $("#role")

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
          chan.push("new:msg", {csrf: $csrf.val(), userid: $userid.val(), user: $username.val(), sub: $usersub.val(), adi: $adi.val(), body: $input.val(), tag: $tag.val(), role: $role.val()})
          $input.val("")
        }
      }
    })

    chan.on("history:msgs", msgs => {
      for (var i = 0; msgs.history.length > i; i++) {
        var logs = decodeURIComponent(escape(window.atob( msgs.history[i] )))
        console.info("=============")
        console.info(logs)
        var msg = {user : logs.split("~")[1],
                  sub : logs.split("~")[2], 
                  adi : logs.split("~")[3],
                  body : logs.split("~")[4],
                  tag: logs.split("~")[5],
                  role: logs.split("~")[6]

        }
        $messages.append(this.messageTemplate(msg))
        scrollTo(0, document.body.scrollHeight)
      }
    })

    chan.on("new:msg", msg => {
      $messages.append(this.messageTemplate(msg))
      if (document.body.scrollHeight - window.pageYOffset < 1000 ){
        scrollTo(0, document.body.scrollHeight)
      }
    })

  }

  static sanitize(html){ return $("<div/>").text(html).html() }

  static messageTemplate(msg){
    let username = this.sanitize(msg.user || "anonymous")
    let usersub  = this.sanitize(msg.sub)
    let adi      = this.sanitize(msg.adi || "false")
    let body     = this.sanitize(msg.body)
    let tag      = this.sanitize(msg.tag)
    let role      = this.sanitize(msg.role)
    if (username == "SYSTEM") {
      return(`<p class="text-center"><span class="time">${moment(body * 1000).fromNow()}</span></p>`)
    }
    console.info(role == "normal_believer")
    if (adi == "true") {
      return(`<p><span class="${adi}">${username}</span> <span class="${tag}">&nbsp;</span> ${body}</p>`)
    } else if (role == "normal_believer") {
      return(`<p><span class="${adi}">${username}</span><span class="normal believer">#${usersub}</span> <span class="${tag}">&nbsp;</span> ${body}</p>`)
    }
    else if (role == "advanced_believer") {
      return(`<p><span class="${adi}">${username}</span><span class="advanced believer">#${usersub}</span> <span class="${tag}">&nbsp;</span> ${body}</p>`)
    }
    else if (role == "true_name") {
      return(`<p><span class="${adi}">${username}</span><span class="true name">#${usersub}</span> <span class="${tag}">&nbsp;</span> ${body}</p>`)
    }else{
      return(`<p><span class="${adi}">${username}</span><span class="sub">#${usersub}</span> <span class="${tag}">&nbsp;</span> ${body}</p>`)
    }
  }

}

$( () => App.init() )
moment.locale('zh-cn')
export default App
