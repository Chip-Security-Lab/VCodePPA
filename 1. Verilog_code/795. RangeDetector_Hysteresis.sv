module RangeDetector_Hysteresis #(
    parameter WIDTH = 8,
    parameter HYST = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] center,
    output reg out_high
);
wire [WIDTH-1:0] upper = center + HYST;
wire [WIDTH-1:0] lower = center - HYST;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_high <= 1'b0;
    else begin
        if(data_in >= upper) out_high <= 1'b1;
        else if(data_in <= lower) out_high <= 1'b0;
    end
end
endmodule