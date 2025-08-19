//SystemVerilog
module prio_encoder (
    input [7:0] req,
    output reg [2:0] code
);
    
    // 合并所有具有相同触发条件的always块
    always @(*) begin
        // 检测请求有效性
        if (|req) begin  // req_valid
            // 优先级编码逻辑
            if (req[7])
                code = 3'h7;
            else if (req[6])
                code = 3'h6;
            else if (req[5])
                code = 3'h5;
            else if (req[4])
                code = 3'h4;
            else if (req[3])
                code = 3'h3;
            else if (req[2])
                code = 3'h2;
            else if (req[1])
                code = 3'h1;
            else  // req[0]
                code = 3'h0;
        end
        else begin
            code = 3'h0;
        end
    end
    
endmodule