//SystemVerilog
module hash_function #(parameter DATA_WIDTH = 32, HASH_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire last_block,
    output reg [HASH_WIDTH-1:0] hash_out,
    output reg hash_valid
);
    // 分解组合逻辑路径的中间寄存器
    reg [HASH_WIDTH-1:0] hash_state;
    reg [HASH_WIDTH-1:0] data_xor_stage1;
    reg last_block_r;
    reg enable_r;
    
    // 第一级流水线：计算输入数据的XOR
    always @(posedge clk) begin
        if (!rst_n) begin
            data_xor_stage1 <= {HASH_WIDTH{1'b0}};
            last_block_r <= 1'b0;
            enable_r <= 1'b0;
        end else begin
            data_xor_stage1 <= data_in[15:0] ^ data_in[31:16];
            last_block_r <= last_block;
            enable_r <= enable;
        end
    end
    
    // 第二级流水线：更新hash状态并生成输出
    always @(posedge clk) begin
        if (!rst_n) begin
            hash_state <= {HASH_WIDTH{1'b1}}; // 初始值
            hash_valid <= 1'b0;
            hash_out <= {HASH_WIDTH{1'b0}};
        end else if (enable_r) begin
            hash_state <= hash_state ^ data_xor_stage1;
            
            if (last_block_r) begin
                hash_valid <= 1'b1;
                hash_out <= hash_state ^ data_xor_stage1;
            end else begin
                hash_valid <= 1'b0;
            end
        end else begin
            // 保持当前值
            hash_valid <= hash_valid;
        end
    end
endmodule