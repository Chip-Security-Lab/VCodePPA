//SystemVerilog
module CircularBuffer #(
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input  wire                  clk,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire                  data_in,
    output wire                  data_out
);

reg [DEPTH-1:0]                    mem;
reg [ADDR_WIDTH-1:0]               wr_ptr, rd_ptr;
reg                                data_out_reg;

// Forward retiming: move register after memory read
always @(posedge clk) begin
    if (wr_en)
        mem[wr_ptr] <= data_in;
    wr_ptr <= wr_ptr + wr_en;
    rd_ptr <= rd_ptr + rd_en;
end

always @(posedge clk) begin
    data_out_reg <= mem[rd_ptr];
end

assign data_out = data_out_reg;

endmodule