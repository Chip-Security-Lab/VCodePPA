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

reg [DW-1:0] cam_array [0:ENTRIES-1];
reg [ENTRIES-1:0] match_lines_next;
integer j;

// Combined write and output register operations
always @(posedge clk) begin
    if (we) begin
        cam_array[wr_addr] <= wr_data;
    end
    match_lines <= match_lines_next;
end

// Match operation with optimized comparison
always @(*) begin
    j = 0;
    while (j < ENTRIES) begin
        match_lines_next[j] = (cam_array[j] == match_data);
        j = j + 1;
    end
end

endmodule