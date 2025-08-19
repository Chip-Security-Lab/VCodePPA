//SystemVerilog
module dual_clock_regfile #(
    parameter DW = 48,
    parameter AW = 5
)(
    input wr_clk,
    input rd_clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input [AW-1:0] rd_addr,
    output [DW-1:0] rd_data
);
reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] sync_reg_0;
reg [DW-1:0] sync_reg_1;
reg [AW-1:0] rd_addr_reg;

// Lookup table for subtraction
reg [DW-1:0] lut_sub [0:255]; // 256 entries for 8-bit input

// Initialize lookup table
initial begin
    integer i, j;
    for (i = 0; i < 256; i = i + 1) begin
        for (j = 0; j < 256; j = j + 1) begin
            lut_sub[i] = i - j; // Populate the lookup table with subtraction results
        end
    end
end

always @(posedge wr_clk) begin
    if (wr_en) mem[wr_addr] <= wr_data;
end

always @(posedge rd_clk) begin
    rd_addr_reg <= rd_addr;
    sync_reg_0 <= mem[rd_addr_reg];
    sync_reg_1 <= sync_reg_0;
end

// Use lookup table for subtraction
wire [DW-1:0] sub_result;
assign sub_result = lut_sub[sync_reg_1[7:0]]; // Assuming we want to subtract from the lower 8 bits

assign rd_data = sub_result; // Output the subtraction result
endmodule