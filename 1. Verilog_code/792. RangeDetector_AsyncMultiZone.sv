module RangeDetector_AsyncMultiZone #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] bounds [ZONES*2-1:0],
    output [ZONES-1:0] zone_flags
);
generate
genvar i;
for(i=0; i<ZONES; i=i+1) begin : gen_zone
    assign zone_flags[i] = (data_in >= bounds[2*i]) && 
                          (data_in <= bounds[2*i+1]);
end
endgenerate
endmodule