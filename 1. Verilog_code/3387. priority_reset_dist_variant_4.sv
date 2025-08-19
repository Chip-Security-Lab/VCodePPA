//SystemVerilog
module priority_reset_dist(
    input wire [3:0] reset_sources,
    input wire [3:0] priority_levels,
    output reg [7:0] reset_outputs
);
    reg [3:0] highest_active;
    
    // Optimized highest active reset source determination
    always @(*) begin
        casez (reset_sources)
            4'b1???: highest_active = 4'd3;
            4'b01??: highest_active = 4'd2;
            4'b001?: highest_active = 4'd1;
            4'b0001: highest_active = 4'd0;
            default: highest_active = 4'd15;
        endcase
    end
    
    // Optimized reset outputs generation
    always @(*) begin
        reset_outputs = (highest_active < 4'd15) ? (8'hFF >> priority_levels[highest_active]) : 8'h0;
    end
endmodule