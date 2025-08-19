module priority_reset_dist(
    input wire [3:0] reset_sources,
    input wire [3:0] priority_levels,
    output wire [7:0] reset_outputs
);
    wire highest_active = reset_sources[3] ? 4'd3 :
                         reset_sources[2] ? 4'd2 :
                         reset_sources[1] ? 4'd1 :
                         reset_sources[0] ? 4'd0 : 4'd15;
    assign reset_outputs = (highest_active < 4'd15) ? 
                          (8'hFF >> priority_levels[highest_active]) : 8'h0;
endmodule
