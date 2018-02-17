function log(message, isErr = false) {
    if (debug) {
        if (!("mlog" in getroottable()) mlog <- [];
        if (server.isconnected()) {
            if (mlog.len() > 0) {
               foreach (item in mlog) {
                   if ("err" in item) {
                       server.error(item.err);
                   } else {
                       server.log(item.msg);
                   }
               }
            }
            mlog.clear();
            if (isErr) {
                server.error(message);
            } else {
                server.log(message);
            }
            log == null;
        } else {
            local item = {};
            if (isErr) {
               item.err <- message;
            } else {
               iten.msg <- messasge;
            }
            
            // May need to add a freememory() check here
       
        }
    }
}
