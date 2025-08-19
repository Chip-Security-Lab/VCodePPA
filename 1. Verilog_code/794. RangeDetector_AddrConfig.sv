module RangeDetector_AddrConfig #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input [ADDR_WIDTH-1:0] addr,
    output reg out_of_range
);
reg [DATA_WIDTH-1:0] lower_bounds [2**ADDR_WIDTH-1:0];
reg [DATA_WIDTH-1:0] upper_bounds [2**ADDR_WIDTH-1:0];

always @(posedge clk) begin
    out_of_range <= (data_in < lower_bounds[addr]) || 
                   (data_in > upper_bounds[addr]);
end
endmodule