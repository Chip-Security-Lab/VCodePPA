//SystemVerilog
module phase_aligner #(parameter PHASES=4, DATA_W=8) (
    input clk, rst,
    input [DATA_W-1:0] phase_data_0,
    input [DATA_W-1:0] phase_data_1,
    input [DATA_W-1:0] phase_data_2,
    input [DATA_W-1:0] phase_data_3,
    output reg [DATA_W-1:0] aligned_data
);
    // 将直接连接到输入的寄存器移除，直接使用输入信号
    wire [DATA_W-1:0] xor_result;
    
    // 计算异或结果的组合逻辑
    assign xor_result = phase_data_1 ^ phase_data_2 ^ phase_data_3 ^ phase_data_0;
    
    // 将寄存器移到组合逻辑之后
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            aligned_data <= 0;
        end else begin
            aligned_data <= xor_result;
        end
    end
endmodule