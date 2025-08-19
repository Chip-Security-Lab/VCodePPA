module tdp_ram_rw_priority #(
    parameter D_WIDTH = 16,
    parameter A_WIDTH = 9,
    parameter PORT_A_WRITE_FIRST = 1,
    parameter PORT_B_READ_FIRST = 1
)(
    input clk,
    // Port A (configurable priority)
    input [A_WIDTH-1:0] a_adr,
    input [D_WIDTH-1:0] a_din,
    output reg [D_WIDTH-1:0] a_dout,
    input a_we,
    // Port B (configurable priority)
    input [A_WIDTH-1:0] b_adr,
    input [D_WIDTH-1:0] b_din,
    output reg [D_WIDTH-1:0] b_dout,
    input b_we
);

reg [D_WIDTH-1:0] ram [0:(1<<A_WIDTH)-1];

// Port A with write-first/read-first selection
always @(posedge clk) begin
    if (PORT_A_WRITE_FIRST) begin
        if (a_we) ram[a_adr] <= a_din;
        a_dout <= a_we ? a_din : ram[a_adr];
    end else begin
        a_dout <= ram[a_adr];
        if (a_we) ram[a_adr] <= a_din;
    end
end

// Port B with read-first behavior
always @(posedge clk) begin
    if (PORT_B_READ_FIRST) begin
        b_dout <= ram[b_adr];
        if (b_we) ram[b_adr] <= b_din;
    end else begin
        if (b_we) ram[b_adr] <= b_din;
        b_dout <= b_we ? b_din : ram[b_adr];
    end
end
endmodule
