//SystemVerilog
module sbox_substitution #(parameter ADDR_WIDTH = 4, DATA_WIDTH = 8) (
    input wire clk, rst,
    input wire enable,
    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    // 流水线控制信号
    input wire valid_in,
    output reg valid_out,
    input wire ready_in,
    output wire ready_out
);
    // S-box 存储
    reg [DATA_WIDTH-1:0] sbox [0:(1<<ADDR_WIDTH)-1];
    
    // 流水线阶段寄存器
    reg [DATA_WIDTH-1:0] sbox_lookup_stage1;
    reg [DATA_WIDTH-1:0] data_in_stage1;
    reg valid_stage1;
    
    // 流水线控制信号
    assign ready_out = ready_in || !valid_stage1;
    
    // 第一级流水线 - 地址查找
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sbox_lookup_stage1 <= 0;
            data_in_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else if (enable && ready_out) begin
            sbox_lookup_stage1 <= sbox[addr_in];
            data_in_stage1 <= data_in;
            valid_stage1 <= valid_in;
        end
        else if (ready_in) begin
            valid_stage1 <= 0;
        end
    end
    
    // 第二级流水线 - 异或操作和输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
            valid_out <= 0;
        end
        else if (enable && ready_in) begin
            if (valid_stage1) begin
                data_out <= sbox_lookup_stage1 ^ data_in_stage1;
                valid_out <= valid_stage1;
            end
            else begin
                valid_out <= 0;
            end
        end
        else if (!ready_in) begin
            // 如果下游未准备好，保持当前状态
        end
        else begin
            valid_out <= 0;
        end
    end
endmodule