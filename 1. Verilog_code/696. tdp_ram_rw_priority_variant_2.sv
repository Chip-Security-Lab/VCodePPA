//SystemVerilog
module tdp_ram_rw_priority #(
    parameter D_WIDTH = 16,
    parameter A_WIDTH = 9,
    parameter PORT_A_WRITE_FIRST = 1,
    parameter PORT_B_READ_FIRST = 1
)(
    input clk,
    input [A_WIDTH-1:0] a_adr,
    input [D_WIDTH-1:0] a_din,
    output reg [D_WIDTH-1:0] a_dout,
    input a_we,
    input [A_WIDTH-1:0] b_adr,
    input [D_WIDTH-1:0] b_din,
    output reg [D_WIDTH-1:0] b_dout,
    input b_we
);

// LUT-based subtractor implementation
reg [D_WIDTH-1:0] lut_sub [0:255];
reg [D_WIDTH-1:0] ram [0:(1<<A_WIDTH)-1];

// Initialize LUT for 8-bit subtraction
initial begin
    for (int i = 0; i < 256; i++) begin
        for (int j = 0; j < 256; j++) begin
            lut_sub[i*256 + j] = i - j;
        end
    end
end

// Port A with write-first/read-first selection
always @(posedge clk) begin
    if (PORT_A_WRITE_FIRST) begin
        if (a_we) begin
            ram[a_adr] <= a_din;
            a_dout <= a_din;
        end else begin
            a_dout <= ram[a_adr];
        end
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
        if (b_we) begin
            ram[b_adr] <= b_din;
            b_dout <= b_din;
        end else begin
            b_dout <= ram[b_adr];
        end
    end
end
endmodule