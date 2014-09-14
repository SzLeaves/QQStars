import QtQuick 2.2
import mywindow 1.0

Item{
    id: friendlist_main
    clip:true
    width: parent.width
    height: parent.height
    function getGroupListFinished( data ) {
        data = JSON.parse(data)
        if(data.retcode ==0 ) {
            var groupmarknames = data.result.gmarklist//群备注信息
            for( var i=0; i<groupmarknames.length;++i ) {
                utility.setValue(groupmarknames[i].uin+"alias", groupmarknames[i].markname)//储存备注信息
            }
            var list_info = data.result.gnamelist
            mymodel.append({"obj_name": "群", "obj_listData": JSON.stringify(list_info) })
        }
    }
    function getDiscusListFinished(data) {//获取讨论组列表完
        data = JSON.parse(data)
        if(data.retcode ==0 ) {
            var list_info = data.result.dnamelist
            console.log("讨论组获取成功："+list_info.length)
            mymodel.append({"obj_name": "讨论组", "obj_listData": JSON.stringify(list_info)})
        }
    }
    Component.onCompleted: {
        myqq.getGroupList(getGroupListFinished) //获取群列表
        myqq.getDiscusList(getDiscusListFinished) //讨论组列表
    }

    MyScrollView{
        anchors.fill: parent
        Item{
            height: list.contentHeight+10
            width: friendlist_main.width
            implicitHeight: height
            implicitWidth: width
            ListView{
               id: list
               interactive: false
               anchors.fill: parent
               model: ListModel{
                   id:mymodel
               }
               spacing :10
               delegate: component1
            }
        }
    }
    Component{
        id: component1
        Item{
            id: root
            clip: true
            property string name: obj_name
            property var list_data: JSON.parse(obj_listData)
            onList_dataChanged: {
                for( var i=0; i< list_data.length;++i ) {
                    model.append({"obj_info": list_data[i]})
                }
            }

            property alias model: mymodel2
            height: text_name.implicitHeight
            width: parent.width
            
            state: "close"
            function stateSwitch(){
                if( state=="close" )
                    state = "unfold"
                else
                    state="close"
            }
        
            states: [
                State {
                    name: "close"
                    PropertyChanges {
                        target: root
                        height: text_name.implicitHeight
                    }
                },
                State {
                    name: "unfold"
                    PropertyChanges {
                        target: root
                        height: text_name.implicitHeight+list2.contentHeight+10
                    }
                }
            ]
            
            Text{
                id: image_icon
                x:10
                anchors.verticalCenter: text_name.verticalCenter
                text: root.state == "close"?"+":"-"
                font.pointSize: 16
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        root.stateSwitch()
                    }
                }
            }
        
            Text{
                id: text_name
                text: name
                anchors.left: image_icon.right
                anchors.leftMargin: 10
                font.pointSize: 10
                font.bold: true
            }
        
            ListView{
                id: list2
                model: ListModel{
                    id:mymodel2
                }
                interactive: false
                spacing: 10
                delegate: component2
                anchors.top: text_name.bottom
                anchors.topMargin: 10
                width: parent.width
                height: parent.height
            }
        }
    }
    Component{
        id: component2
        Item{
            width: parent.width
            height: avatar.height
            property var info: obj_info
            property var code: info.code
            property string uin: {
                if( info.gid ){
                    utility.setValue(info.gid+"nick", info.name)
                    return info.gid
                }else{
                    utility.setValue(info.did+"nick", info.name)
                    return info.did
                }
            }
            property string account: utility.getValue(uin+"account", "")//真实的群号
            
            function getQQFinished(data){//获取真实群号后调用的函数
                data = JSON.parse(data)
                if( data.retcode==0 ){
                    account = data.result.account
                    utility.setValue(uin+"account", account)//保存真实qq
                    if( avatar.source=="qrc:/images/avatar.png" )//如果头像不存在
                        myqq.downloadImage("http://p.qlogo.cn/gh/"+account+"/"+account+"/40", "group"+account, "40", getAvatarFinished)//下载头像
                }
            }
            function getAvatarFinished( path ,name){
                var imageName = path+"/"+name+".png"
                utility.setValue(uin+name, imageName)//保存自己头像的地址
                avatar.source = imageName
            }

            Component.onCompleted: {
                if( code ){
                    if(account==""){
                        myqq.getFriendQQ(code, getQQFinished)
                    }else{
                        if( avatar.source=="qrc:/images/avatar.png" )//如果头像不存在
                            myqq.downloadImage("http://p.qlogo.cn/gh/"+account+"/"+account+"/40", "group"+account, "40", getAvatarFinished)//下载头像
                    }
                }
            }

            MyImage{
                id: avatar
                x:10
                width:40
                maskSource: "qrc:/images/bit.bmp"
                source: utility.getValue(parent.uin+"avatar-40", "qrc:/images/avatar.png")
                onLoadError: {
                    avatar.source = "qrc:/images/avatar.png"
                }
            }
            Text{
                id:text_nick
                anchors.top: avatar.top
                anchors.left: avatar.right
                anchors.leftMargin: 10
                font.pointSize: 14
                text: utility.getValue(info.gid+"alias", info.name)
            }
        }
    }
}