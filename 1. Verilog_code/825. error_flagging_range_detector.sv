module error_flagging_range_detector(
    input wire clk, rst,
    input wire [31:0] data_in,
    input wire [31:0] lower_lim, upper_lim,
    output reg in_range,
    output reg error_flag // Flags invalid range where upper < lower
);
    wire valid_range = (upper_lim >= lower_lim);
    wire in_bounds = (data_in >= lower_lim) && (data_in <= upper_lim);
    
    always @(posedge clk) begin
        if (rst) begin in_range <= 1'b0; error_flag <= 1'b0; end
        else begin
            error_flag <= !valid_range;
            in_range <= valid_range && in_bounds;
        end
    end
endmodule