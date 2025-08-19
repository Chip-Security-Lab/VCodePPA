module RangeDetector_APB #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input psel, penable, pwrite,
    input [ADDR_WIDTH-1:0] paddr,
    input [WIDTH-1:0] pwdata,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] prdata,
    output reg out_range
);
reg [WIDTH-1:0] thresholds[0:1]; // 0:lower 1:upper

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        thresholds[0] <= 0;
        thresholds[1] <= {WIDTH{1'b1}};
    end
    else if(psel && penable && pwrite) begin
        thresholds[paddr] <= pwdata;
    end
end

always @(posedge clk) begin
    out_range <= (data_in < thresholds[0]) || (data_in > thresholds[1]);
    prdata <= thresholds[paddr];
end
endmodule