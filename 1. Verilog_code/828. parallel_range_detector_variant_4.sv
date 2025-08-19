//SystemVerilog
module parallel_range_detector(
    input wire clk, rst_n,
    input wire [15:0] data_val,
    input wire [15:0] range_start, range_end,
    output reg lower_than_range,
    output reg inside_range,
    output reg higher_than_range
);
    always @(posedge clk or negedge rst_n) begin
        lower_than_range <= !rst_n ? 1'b0 : (data_val < range_start);
        inside_range <= !rst_n ? 1'b0 : ((data_val >= range_start) && (data_val <= range_end));
        higher_than_range <= !rst_n ? 1'b0 : (data_val > range_end);
    end
endmodule