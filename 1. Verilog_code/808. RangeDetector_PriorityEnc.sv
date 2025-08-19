module RangeDetector_PriorityEnc #(
    parameter WIDTH = 8,
    parameter ZONES = 4
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] zone_limits [ZONES:0],
    output reg [$clog2(ZONES)-1:0] zone_num
);
integer i;
always @(*) begin
    zone_num = 0;
    for(i = 0; i < ZONES; i = i+1) begin
        if(data_in >= zone_limits[i] && data_in < zone_limits[i+1]) begin
            zone_num = i;
        end
    end
end
endmodule