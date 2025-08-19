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

// Memory array with buffered outputs
reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
reg [DATA_WIDTH-1:0] mem_x_buf, mem_y_buf;

// Clock gating signals with buffering
wire clk_gated;
reg clk_en, clk_gated_reg;
reg clk_en_buf;

// Combined clock gating and memory access logic
always @(posedge sys_clk) begin
    clk_en <= pwr_en & (x_ce | y_ce);
    clk_en_buf <= clk_en;
    clk_gated_reg <= clk_en_buf;
    
    if (clk_gated_reg) begin
        if (x_ce) begin
            if (x_we) begin
                mem[x_addr] <= x_din;
            end
            mem_x_buf <= mem[x_addr];
            x_dout <= mem_x_buf;
        end
        if (y_ce) begin
            if (y_we) begin
                mem[y_addr] <= y_din;
            end
            mem_y_buf <= mem[y_addr];
            y_dout <= mem_y_buf;
        end
    end
end

assign clk_gated = sys_clk & clk_gated_reg;

endmodule