//SystemVerilog
module error_flagging_range_detector(
    input wire clk, rst,
    input wire [31:0] data_in,
    input wire [31:0] lower_lim, upper_lim,
    output reg in_range,
    output reg error_flag
);
    // Combined logic for all stages
    reg valid_range;
    reg lower_compare;
    reg upper_compare;
    reg in_bounds;
    
    always @(posedge clk) begin
        if (rst) begin
            valid_range <= 1'b0;
            lower_compare <= 1'b0;
            upper_compare <= 1'b0;
            in_bounds <= 1'b0;
            in_range <= 1'b0;
            error_flag <= 1'b0;
        end
        else begin
            // Flattened logic combining all stages
            valid_range <= (upper_lim >= lower_lim);
            lower_compare <= (data_in >= lower_lim);
            upper_compare <= (data_in <= upper_lim);
            in_bounds <= lower_compare && upper_compare;
            in_range <= valid_range && in_bounds;
            error_flag <= !valid_range;
        end
    end
endmodule