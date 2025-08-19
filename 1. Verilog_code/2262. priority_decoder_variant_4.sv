//SystemVerilog
module priority_decoder(
    input [7:0] req_in,
    output reg [2:0] grant_addr,
    output reg valid
);
    // 计算valid信号
    always_comb begin
        valid = |req_in;
    end
    
    // 优先级编码 - 使用布尔逻辑简化表达式
    always_comb begin
        grant_addr[2] = req_in[4] | req_in[5] | req_in[6] | req_in[7];
        grant_addr[1] = req_in[2] | req_in[3] | req_in[6] | req_in[7];
        grant_addr[0] = req_in[1] | req_in[3] | req_in[5] | req_in[7];
    end
endmodule