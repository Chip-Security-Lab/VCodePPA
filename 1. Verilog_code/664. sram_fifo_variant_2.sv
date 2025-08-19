//SystemVerilog
module sram_fifo #(
    parameter DW = 32,
    parameter DEPTH = 8
)(
    input wr_clk,
    input wr_en,
    input [DW-1:0] din,
    input rd_clk,
    input rd_en,
    output [DW-1:0] dout,
    output full,
    output empty
);

// Memory array
reg [DW-1:0] mem [0:DEPTH-1];

// Pointer registers with proper width
reg [$clog2(DEPTH):0] wr_ptr = 0;
reg [$clog2(DEPTH):0] rd_ptr = 0;

// Pre-calculate pointer differences
wire [$clog2(DEPTH):0] ptr_diff = wr_ptr - rd_ptr;
wire is_full = (ptr_diff == DEPTH);
wire is_empty = (ptr_diff == 0);

// Write control signals
wire wr_addr_valid = wr_en && !is_full;
wire [$clog2(DEPTH)-1:0] wr_addr = wr_ptr[$clog2(DEPTH)-1:0];

// Read control signals
wire rd_addr_valid = rd_en && !is_empty;
wire [$clog2(DEPTH)-1:0] rd_addr = rd_ptr[$clog2(DEPTH)-1:0];

// Write pointer update with early termination
always @(posedge wr_clk) begin
    if (wr_addr_valid) begin
        mem[wr_addr] <= din;
        wr_ptr <= wr_ptr + 1'b1;
    end
end

// Read pointer update with early termination
always @(posedge rd_clk) begin
    if (rd_addr_valid) begin
        rd_ptr <= rd_ptr + 1'b1;
    end
end

// Status signals
assign full = is_full;
assign empty = is_empty;

// Output data with registered read
reg [DW-1:0] dout_reg;
always @(posedge rd_clk) begin
    if (rd_addr_valid) begin
        dout_reg <= mem[rd_addr];
    end
end
assign dout = dout_reg;

endmodule