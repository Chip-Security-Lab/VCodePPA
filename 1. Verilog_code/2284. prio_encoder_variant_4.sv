//SystemVerilog
// 顶层模块
module prio_encoder (
    input [7:0] req,
    output [2:0] code
);
    // 直接编码最高优先级请求
    assign code = req[7] ? 3'h7 :
                  req[6] ? 3'h6 :
                  req[5] ? 3'h5 :
                  req[4] ? 3'h4 :
                  req[3] ? 3'h3 :
                  req[2] ? 3'h2 :
                  req[1] ? 3'h1 :
                  req[0] ? 3'h0 : 3'h0;
endmodule