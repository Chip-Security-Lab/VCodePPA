//SystemVerilog
module int_ctrl_threshold #(
    parameter WIDTH = 6,
    parameter THRESHOLD = 3
)(
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg valid,
    output reg [2:0] code
);
    // 使用条件求和减法算法创建阈值掩码
    wire [WIDTH-1:0] threshold_value = THRESHOLD;
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] sub_result;
    
    // 条件求和减法器实现
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_gen
            assign sub_result[i] = req[i] ^ threshold_value[i] ^ borrow[i];
            assign borrow[i+1] = (~req[i] & threshold_value[i]) | 
                               (~req[i] & borrow[i]) | 
                               (threshold_value[i] & borrow[i]);
        end
    endgenerate
    
    // 生成掩码: 只有当req >= THRESHOLD时才为有效值
    wire [WIDTH-1:0] masked_req;
    assign masked_req = ~borrow[WIDTH] ? req & ~((1 << THRESHOLD) - 1) : {WIDTH{1'b0}};
    
    reg [2:0] next_code;
    reg next_valid;
    
    // 计算下一状态逻辑
    always @(*) begin
        next_valid = |masked_req;
        next_code = 3'b0;
        
        if (masked_req[5]) next_code = 3'd5;
        else if (masked_req[4]) next_code = 3'd4;
        else if (masked_req[3]) next_code = 3'd3;
        // 低于阈值的位被掩码屏蔽 (THRESHOLD=3)
    end
    
    // 寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
            code <= 3'b0;
        end else begin
            valid <= next_valid;
            code <= next_code;
        end
    end
endmodule