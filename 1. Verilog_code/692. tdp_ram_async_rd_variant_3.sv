//SystemVerilog
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
reg [AW-1:0] addr_a_reg, addr_b_reg;
reg [DW-1:0] data_a_reg, data_b_reg;
reg wr_a_reg, wr_b_reg;
reg [DW-1:0] a_dout_reg, b_dout_reg;

// Register inputs to improve timing
always @(posedge clk) begin
    addr_a_reg <= a_addr;
    addr_b_reg <= b_addr;
    data_a_reg <= a_din;
    data_b_reg <= b_din;
    wr_a_reg <= a_wr;
    wr_b_reg <= b_wr;
end

// Asynchronous read with registered addresses
assign a_dout = storage[addr_a_reg];
assign b_dout = storage[addr_b_reg];

// Synchronous write with async reset
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < DEPTH; i++) begin
            storage[i] <= {DW{1'b0}};
        end
    end else begin
        if (wr_a_reg) storage[addr_a_reg] <= data_a_reg;
        if (wr_b_reg) storage[addr_b_reg] <= data_b_reg;
    end
end

endmodule