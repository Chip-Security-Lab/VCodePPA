//SystemVerilog
// SystemVerilog
module simon_light #(
    parameter ROUNDS = 44
)(
    input clk, load_key,
    input [63:0] block_in,
    input [127:0] key_in,
    output reg [63:0] block_out
);
    reg [63:0] key_schedule [0:ROUNDS-1];
    reg [31:0] left, right;
    reg [31:0] new_left;
    wire [31:0] left_rotated_1, left_rotated_8;
    integer r;
    
    // 优化的桶形移位器结构 - 同时实现1位和8位循环左移
    assign left_rotated_1 = {left[30:0], left[31]};
    assign left_rotated_8 = {left[23:0], left[31:24]};
    
    // 优化的密钥计划更新和块处理
    always @(posedge clk) begin
        if (load_key) begin
            // 并行计算密钥调度
            key_schedule[0] <= key_in[63:0];
            for(r=1; r<ROUNDS; r=r+1) begin
                // 优化的密钥生成逻辑
                key_schedule[r] <= {key_schedule[r-1][60:0], 
                                   key_schedule[r-1][63:61] ^ 3'h5};
            end
        end else begin
            // 优化的数据流和并行计算
            left = block_in[63:32];
            right = block_in[31:0];
            
            // 增强的扩散函数
            new_left = right ^ left_rotated_1 ^ (left_rotated_1 & left_rotated_8) ^ key_schedule[0][31:0];
            
            // 更新输出区块
            block_out <= {right, new_left};
        end
    end
endmodule