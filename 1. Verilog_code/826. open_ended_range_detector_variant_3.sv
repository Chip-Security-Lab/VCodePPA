//SystemVerilog
module open_ended_range_detector(
    input wire [11:0] data,
    input wire [11:0] bound_value,
    input wire direction, // 0=lower_bound_only, 1=upper_bound_only
    output reg in_valid_zone
);
    // Karatsuba multiplier implementation
    wire [11:0] data_high = data[11:6];
    wire [11:0] data_low = data[5:0];
    wire [11:0] bound_high = bound_value[11:6];
    wire [11:0] bound_low = bound_value[5:0];
    
    wire [23:0] z0 = data_low * bound_low;
    wire [23:0] z1 = (data_high + data_low) * (bound_high + bound_low);
    wire [23:0] z2 = data_high * bound_high;
    
    wire [23:0] result = (z2 << 12) + ((z1 - z2 - z0) << 6) + z0;
    
    always @(*) begin
        if (direction == 1'b1) begin
            in_valid_zone = (result[23:12] <= bound_value);
        end
        else begin
            in_valid_zone = (result[23:12] >= bound_value);
        end
    end
endmodule