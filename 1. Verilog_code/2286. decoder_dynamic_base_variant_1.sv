//SystemVerilog

module decoder_dynamic_base (
    input [7:0] base_addr,
    input [7:0] current_addr,
    output reg sel
);
    // 创建一个额外的比较信号
    wire [3:0] xnor_result;
    
    // 使用XNOR位级操作比较高4位
    assign xnor_result[0] = ~(current_addr[4] ^ base_addr[4]);
    assign xnor_result[1] = ~(current_addr[5] ^ base_addr[5]);
    assign xnor_result[2] = ~(current_addr[6] ^ base_addr[6]);
    assign xnor_result[3] = ~(current_addr[7] ^ base_addr[7]);
    
    // 组合逻辑确定是否选择
    always @(*) begin
        sel = &xnor_result; // 所有位都匹配时sel为1
    end
endmodule