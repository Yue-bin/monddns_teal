return {
    include = {
        "./",      -- 1. 首先在当前目录 (项目根目录) 寻找
        "extypes/" -- 2. 如果找不到，就去 typedefs 目录里寻找
    }
}
