module tdp_ram_async_rd #(
    parameter DW = 16,
    parameter AW = 5,
    parameter DEPTH = 32
)(
    input clk, rst_n,
    // Port A
    input [AW-1:0] a_addr,
    input [DW-1:0] a_din,
    output [DW-1:0] a_dout,
    input a_wr,
    // Port B
    input [AW-1:0] b_addr,
    input [DW-1:0] b_din,
    output [DW-1:0] b_dout,
    input b_wr
);

reg [DW-1:0] storage [0:DEPTH-1];
integer i;

// Asynchronous read
assign a_dout = storage[a_addr];
assign b_dout = storage[b_addr];

// Synchronous write with async reset
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < DEPTH; i = i + 1)
            storage[i] <= 0;
    end else begin
        if (a_wr) storage[a_addr] <= a_din;
        if (b_wr) storage[b_addr] <= b_din;
    end
end
endmodule