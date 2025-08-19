//SystemVerilog
module BusMask_AND (
    input  wire        clk,           // 时钟信号
    input  wire        rst_n,         // 复位信号，低有效
    input  wire [15:0] bus_in,        // 输入总线数据
    input  wire [15:0] mask,          // 输入掩码
    output reg  [15:0] masked_bus     // 掩码后的输出总线
);

    // 数据流：直接在输入端执行掩码操作的组合逻辑
    wire [7:0] masked_lower_comb, masked_upper_comb;
    
    assign masked_lower_comb = bus_in[7:0] & mask[7:0];
    assign masked_upper_comb = bus_in[15:8] & mask[15:8];
    
    // 将寄存器移到组合逻辑之后，减少输入到第一级寄存器的延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_bus <= 16'h0;
        end else begin
            masked_bus <= {masked_upper_comb, masked_lower_comb};
        end
    end

endmodule