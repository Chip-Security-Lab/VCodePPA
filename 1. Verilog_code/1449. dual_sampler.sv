module dual_sampler (
    input clk, din,
    output reg rise_data, fall_data
);
always @(posedge clk) rise_data <= din;
always @(negedge clk) fall_data <= din;
endmodule