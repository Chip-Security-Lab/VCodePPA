//SystemVerilog
module tdp_ram_clock_gating #(
    parameter DATA_WIDTH = 18,
    parameter ADDR_WIDTH = 9
)(
    input sys_clk, 
    input pwr_en,
    // Port X
    input [ADDR_WIDTH-1:0] x_addr,
    input [DATA_WIDTH-1:0] x_din,
    output reg [DATA_WIDTH-1:0] x_dout,
    input x_we, x_ce,
    // Port Y
    input [ADDR_WIDTH-1:0] y_addr,
    input [DATA_WIDTH-1:0] y_din,
    output reg [DATA_WIDTH-1:0] y_dout,
    input y_we, y_ce
);

reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
wire clk_gated = sys_clk & pwr_en;

always @(posedge clk_gated) begin
    // Port X operations
    if (x_ce) begin
        if (x_we) begin
            mem[x_addr] <= x_din;
        end
        x_dout <= mem[x_addr];
    end
    
    // Port Y operations
    if (y_ce) begin
        if (y_we) begin
            mem[y_addr] <= y_din;
        end
        y_dout <= mem[y_addr];
    end
end

endmodule