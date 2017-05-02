import {Socket, LongPoller} from "phoenix"

class App {

  static init(){
    var $status    = $("#status")
    var $history  = $(".history")
    var $input     = $(".content")

    let socket = new Socket("/socket", {
      logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
    })

    socket.connect({token: window.userToken})
    socket.onOpen( ev => console.log("OPEN", ev) )
    socket.onError( ev => console.log("ERROR", ev) )
    socket.onClose( ev => console.log("CLOSE", ev))

    var channel = socket.channel("rooms:lobby")
    channel.join().receive("ignore", () => console.log("auth error"))
               .receive("ok", () => console.log("join ok"))
               .after(10000, () => console.log("Connection interruption"))
    channel.onError(e => console.log("something went wrong", e))
    channel.onClose(e => console.log("channel closed", e))

    $input.off("keypress").on("keypress", e => {
      if (e.keyCode == 13) {
        if ($.trim($input.val()).length > 0) {
          if (isAdmin == "true"){
            var contentArray = $input.val().split(":")
            if ($input.val().indexOf("top:") == 0){
              channel.push("update:top:notice", {notice: contentArray[1]})
              $input.val("");
              return
            }
            if ($input.val().indexOf("R:") == 0){
              channel.push("reset:role", {userNumber: contentArray[1]})
              $input.val("");
              return
            }
            if ($input.val().indexOf("L:") == 0){
              channel.push("auth:beginner", {userNumber: contentArray[1]})
              $input.val("");
              return
            }
            if ($input.val().indexOf("K:") == 0){  
              channel.push("auth:helpful_user", {userNumber: contentArray[1]})
              $input.val("");
              return
            }
            if ($input.val().indexOf("G:") == 0){  
              channel.push("auth:advanced_user", {userNumber: contentArray[1]})
              $input.val("");
              return
            }
            if ($input.val().indexOf("V:") == 0){  
              channel.push("auth:certified_guest", {userNumber: contentArray[1]})
              $input.val("");
              return
            }
            if ($input.val().indexOf("X:") == 0){  
              channel.push("ban", {userNumber: contentArray[1], minutes: contentArray[2], reason: contentArray[3]})
              $input.val("");
              return
            }
            if ($input.val().indexOf("J:") == 0){
              channel.push("remove:ban", {userNumber: contentArray[1]})
              $input.val("");
              return
            }
            if ($input.val().indexOf("VX:") == 0){  
              channel.push("view:ban_reason", {userNumber: contentArray[1] })
              $input.val("");
              return
            }
          }
          if (username == "用户" || username == "Member"){
            channel.push("update:name", {template: "请修改昵称后再发言" })
            $input.val("");
            return
          }
          channel.push("new:msg", {body: $input.val()})
          $input.val("");
        }
      }
    })

    channel.on("history:msgs", msgs => {
      for (var i = 0; msgs.history.length > i; i++) {
        var tempHistory = decodeURIComponent(escape(window.atob( msgs.history[i] ))).replace(/\'/g, "\"");
        var history = JSON.parse(tempHistory);
        var msg = {name : history.name,
          number : history.number, 
          is_admin : history.is_admin,
          body : history.payload || history.body,
          role: history.role,
          timestamp: history.timestamp
        }
        $history.append(this.messageTemplate(msg))
      }
      $history[0].scrollTop = $history[0].scrollHeight;
    })

    channel.on("new:msg", msg => {
      switch(msg.action)
      {
        case  "reset_role":
          msg.body = "用户已被取消角色"
          break;
        case  "auth_beginner":
          msg.body = "用户已被设为小韭菜"
          break;
        case  "auth_helpful_user":
          msg.body = "用户已被设为热心用户"
          break;
        case  "auth_advanced_user":
          msg.body = "用户已被设为高级用户"
          break;
        case  "auth_certified_guest":
          msg.body = "用户已被设为认证嘉宾"
          break;
        case  "ban":
          msg.body = "用户「"+msg.ban_name+"」已被管理员禁言"
          break;
        case  "update_top_notice":
          msg.body = "聊天室置顶公告设置成功,刷新查看"
          break;
        case  "update_name":
          msg.body = "请修改昵称后再发言"
          break;
        case  "remove_ban":
          msg.body = "用户「"+msg.ban_name+"」已被解禁"
          break;

      }
      $history.append(this.messageTemplate(msg))
      if ($history[0].scrollTop + 60 > ($history[0].scrollHeight - $history[0].clientHeight)){
        $history[0].scrollTop = $history[0].scrollHeight;
      }
    })

    $(document).on('dblclick','.name',function(){
      if (isAdmin == "true"){
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
    let name = this.sanitize(msg.name || "anonymous")
    let number  = this.sanitize(msg.number)
    let is_admin      = this.sanitize(msg.is_admin || "false")
    let body    = this.sanitize(msg.payload || msg.body)
    let role      = this.sanitize(msg.role)
    let timestamp      = this.sanitize(msg.timestamp)

    if (name == "SYSTEM") {
      return(`<p class="system notice"><span class="time">${moment(timestamp * 1000).fromNow()}</span></p>`)
    }
    if (is_admin == "true") {
      return(`<p class="admin"><span class="name">${name}</span><span>${body}</span></p>`)
    } else if (role != "" && role != "null") {
      if (isAdmin == "true"){
        return(`<p class="${role}"><span class="name">${name}</span><span>${number}</span><span>${body}</span></p>`)
      }else{
        return(`<p class="${role}"><span class="name">${name}</span><span></span><span>${body}</span></p>`)
      }
    } else{
      if (isAdmin == "true"){
        return(`<p class="normal"><span class="name">${name}</span><span>${number}</span><span>${body}</span></p>`)
      }else{
        return(`<p class="normal"><span class="name">${name}</span><span></span><span>${body}</span></p>`)
      }
    }
  }
}

$( () => App.init() )
moment.locale('zh-cn')
export default App
