//SystemVerilog
module cam #(
    parameter DW = 16,
    parameter ENTRIES = 32
)(
    input clk,
    input we,
    input [DW-1:0] wr_data,
    input [4:0] wr_addr,
    input [DW-1:0] match_data,
    output reg [ENTRIES-1:0] match_lines
);

// CAM storage array
reg [DW-1:0] cam_array [0:ENTRIES-1];

// Lookup table for address comparison
reg [ENTRIES-1:0] addr_match_table [0:31]; // 5-bit address -> 32 possible values

// Initialize lookup table
initial begin
    integer i, j;
    for (i = 0; i < 32; i = i + 1) begin
        for (j = 0; j < ENTRIES; j = j + 1) begin
            addr_match_table[i][j] = (j == i);
        end
    end
end

// Write operation
always @(posedge clk) begin
    if (we) begin
        cam_array[wr_addr] <= wr_data;
    end
end

// Match operation using lookup table
genvar j;
generate
    for (j = 0; j < ENTRIES; j = j + 1) begin : match_compare
        wire [DW-1:0] entry_data;
        wire addr_match;
        
        assign entry_data = cam_array[j];
        assign addr_match = addr_match_table[wr_addr][j];
        
        always @(*) begin
            match_lines[j] = (entry_data == match_data) & addr_match;
        end
    end
endgenerate

endmodule