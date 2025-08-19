//SystemVerilog
module data_scrambler #(
    parameter POLY_WIDTH = 16,
    parameter POLYNOMIAL = 16'hA001 // x^16 + x^12 + x^5 + 1
) (
    input wire clk, rst_n,
    input wire data_in,
    input wire scrambled_in,
    input wire bypass_scrambler,
    output reg scrambled_out,
    output reg data_out
);
    // LFSR状态寄存器和反馈信号
    reg [POLY_WIDTH-1:0] lfsr_state;
    wire feedback;
    
    // 反馈计算逻辑
    assign feedback = ^(lfsr_state & POLYNOMIAL);
    
    // LFSR状态更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state <= {POLY_WIDTH{1'b1}}; // 初始化为全1
        end else if (!bypass_scrambler) begin
            lfsr_state <= {lfsr_state[POLY_WIDTH-2:0], feedback};
        end
    end
    
    // 加扰输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scrambled_out <= 1'b0;
        end else begin
            scrambled_out <= bypass_scrambler ? data_in : (data_in ^ feedback);
        end
    end
    
    // 解扰输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
        end else if (bypass_scrambler) begin
            data_out <= scrambled_in; // 旁路模式
        end else begin
            data_out <= scrambled_in ^ feedback; // 解扰逻辑
        end
    end
endmodule