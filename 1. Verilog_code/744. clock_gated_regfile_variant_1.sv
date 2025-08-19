//SystemVerilog
module clock_gated_regfile #(
    parameter DW = 40,
    parameter AW = 6
)(
    input clk,
    input global_en,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    // 内存声明
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // 地址解码器和时钟门控信号的流水线
    reg [AW-1:0] addr_r;
    reg region_valid_r;
    
    // 第一级流水线 - 地址解码和时钟门控
    wire region_valid = (addr[5:4] != 2'b11);
    wire region_clk = clk & global_en & region_valid;
    
    // 地址和区域有效性的寄存器
    always @(posedge clk) begin
        if (global_en) begin
            addr_r <= addr;
            region_valid_r <= region_valid;
        end
    end
    
    // 写入操作
    always @(posedge region_clk) begin
        if (wr_en) mem[addr] <= din;
    end
    
    // 读取操作流水线化
    always @(posedge clk) begin
        if (global_en) begin
            dout <= mem[addr_r];
        end
    end
    
endmodule