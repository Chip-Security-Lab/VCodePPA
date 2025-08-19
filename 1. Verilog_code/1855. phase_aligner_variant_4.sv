//SystemVerilog
module phase_aligner #(parameter PHASES=4, DATA_W=8) (
    input clk, rst,
    input [DATA_W-1:0] phase_data_0,
    input [DATA_W-1:0] phase_data_1,
    input [DATA_W-1:0] phase_data_2,
    input [DATA_W-1:0] phase_data_3,
    output reg [DATA_W-1:0] aligned_data
);
    // 寄存器定义
    reg [DATA_W-1:0] sync_reg [0:PHASES-1];
    
    // 中间变量
    reg [DATA_W-1:0] next_sync_0;
    reg [DATA_W-1:0] next_sync_1;
    reg [DATA_W-1:0] next_sync_2;
    reg [DATA_W-1:0] next_sync_3;
    
    reg [DATA_W-1:0] xor_stage1_0;
    reg [DATA_W-1:0] xor_stage1_1;
    reg [DATA_W-1:0] xor_stage2;
    
    // 同步寄存器逻辑
    always @(*) begin
        next_sync_0 = phase_data_1;
        next_sync_1 = phase_data_2;
        next_sync_2 = phase_data_3;
        next_sync_3 = phase_data_0;
    end
    
    integer i;
    
    // 寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for(i=0; i<PHASES; i=i+1)
                sync_reg[i] <= 0;
        end else begin
            sync_reg[0] <= next_sync_0;
            sync_reg[1] <= next_sync_1;
            sync_reg[2] <= next_sync_2;
            sync_reg[3] <= next_sync_3;
        end
    end
    
    // 分级XOR计算
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            xor_stage1_0 <= 0;
            xor_stage1_1 <= 0;
            xor_stage2 <= 0;
            aligned_data <= 0;
        end else begin
            // 第一级XOR
            xor_stage1_0 <= sync_reg[0] ^ sync_reg[1];
            xor_stage1_1 <= sync_reg[2] ^ sync_reg[3];
            
            // 第二级XOR
            xor_stage2 <= xor_stage1_0 ^ xor_stage1_1;
            
            // 输出数据
            aligned_data <= xor_stage2;
        end
    end
endmodule