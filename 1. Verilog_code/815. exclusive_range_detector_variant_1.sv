//SystemVerilog
module exclusive_range_detector(
    input wire clk,
    input wire [9:0] data_val,
    input wire [9:0] lower_val, upper_val,
    input wire inclusive,
    output reg range_match
);

    wire [9:0] lower_bound = lower_val + (inclusive ? 10'd0 : 10'd1);
    wire [9:0] upper_bound = upper_val - (inclusive ? 10'd0 : 10'd1);
    wire range_match_next = (data_val >= lower_bound) && (data_val <= upper_bound);

    always @(posedge clk) begin
        range_match <= range_match_next;
    end

endmodule