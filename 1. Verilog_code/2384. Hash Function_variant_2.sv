//SystemVerilog
module hash_function #(parameter DATA_WIDTH = 32, HASH_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire last_block,
    output reg [HASH_WIDTH-1:0] hash_out,
    output reg hash_valid
);
    // 状态寄存器
    reg [HASH_WIDTH-1:0] hash_state;
    // 优化数据简化逻辑，使用两级异或计算减少关键路径
    wire [7:0] reduced_upper, reduced_lower;
    wire [HASH_WIDTH-1:0] reduced_data;
    
    // 分段计算数据的简化结果，降低扇入并减少延迟
    assign reduced_upper = data_in[31:24] ^ data_in[23:16];
    assign reduced_lower = data_in[15:8] ^ data_in[7:0];
    assign reduced_data = {reduced_upper, reduced_lower};
    
    // 预计算下一个哈希状态以减少关键路径
    wire [HASH_WIDTH-1:0] next_hash_state;
    assign next_hash_state = hash_state ^ reduced_data;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_state <= {HASH_WIDTH{1'b1}}; // 初始值保持不变
            hash_valid <= 1'b0;
            hash_out <= {HASH_WIDTH{1'b0}};
        end else begin
            if (enable) begin
                // 使用预计算的值更新状态
                hash_state <= next_hash_state;
                
                // 条件赋值使用阻塞赋值减少逻辑层次
                hash_valid <= last_block;
                if (last_block) 
                    hash_out <= next_hash_state;
            end else begin
                hash_valid <= 1'b0; // 未启用时清除有效信号
            end
        end
    end
endmodule