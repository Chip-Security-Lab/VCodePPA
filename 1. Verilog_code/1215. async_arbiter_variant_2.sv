//SystemVerilog
// 顶层模块
module async_arbiter #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    wire [WIDTH-1:0] complement_result;
    wire [WIDTH-1:0] priority_mask;
    
    // 实例化子模块
    twos_complement #(.WIDTH(WIDTH)) u_twos_complement (
        .data_i(req_i),
        .result_o(complement_result)
    );
    
    priority_encoder #(.WIDTH(WIDTH)) u_priority_encoder (
        .req_i(req_i),
        .complement_i(complement_result),
        .mask_o(priority_mask),
        .grant_o(grant_o)
    );
endmodule

// 二进制补码计算子模块
module twos_complement #(parameter WIDTH=4) (
    input [WIDTH-1:0] data_i,
    output [WIDTH-1:0] result_o
);
    wire [WIDTH-1:0] ones_comp;
    reg [WIDTH:0] borrow;
    reg [WIDTH-1:0] result;
    
    // 生成一的补码
    assign ones_comp = ~data_i;
    
    // 借位减法器算法计算二的补码
    always @* begin
        borrow[0] = 1'b0;
        
        // 第一位特殊处理
        result[0] = 1'b1 ^ ones_comp[0] ^ borrow[0];
        borrow[1] = (~1'b1 & ones_comp[0]) | (ones_comp[0] & borrow[0]) | (~1'b1 & borrow[0]);
        
        // 处理后续位
        for (integer i = 1; i < WIDTH-1; i = i + 1) begin
            result[i] = 1'b0 ^ ones_comp[i] ^ borrow[i];
            borrow[i+1] = (~1'b0 & ones_comp[i]) | (ones_comp[i] & borrow[i]) | (~1'b0 & borrow[i]);
        end
        
        // 处理最高位
        result[WIDTH-1] = 1'b0 ^ ones_comp[WIDTH-1] ^ borrow[WIDTH-1];
    end
    
    assign result_o = result;
endmodule

// 优先级编码器子模块
module priority_encoder #(parameter WIDTH=4) (
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] complement_i,
    output [WIDTH-1:0] mask_o,
    output [WIDTH-1:0] grant_o
);
    // 计算优先级掩码
    assign mask_o = req_i & complement_i;
    
    // 使用掩码提取最高优先级请求
    assign grant_o = mask_o;
endmodule