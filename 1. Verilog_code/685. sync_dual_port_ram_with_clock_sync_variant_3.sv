//SystemVerilog
module sync_dual_port_ram_with_clock_sync #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    // 使用双端口RAM宏单元
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 合并寄存器以减少延迟
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg we_a_reg, we_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;

    // 优化时序的流水线设计
    always @(posedge clk) begin
        if (rst) begin
            {addr_a_reg, addr_b_reg} <= 0;
            {we_a_reg, we_b_reg} <= 0;
            {din_a_reg, din_b_reg} <= 0;
            {ram_data_a, ram_data_b} <= 0;
            {dout_a, dout_b} <= 0;
        end else begin
            // 地址和数据流水线
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
            din_a_reg <= din_a;
            din_b_reg <= din_b;

            // 写操作和读操作并行执行
            if (we_a_reg) ram[addr_a_reg] <= din_a_reg;
            if (we_b_reg) ram[addr_b_reg] <= din_b_reg;
            
            // 读操作流水线
            ram_data_a <= ram[addr_a_reg];
            ram_data_b <= ram[addr_b_reg];
            
            // 输出流水线
            dout_a <= ram_data_a;
            dout_b <= ram_data_b;
        end
    end

endmodule