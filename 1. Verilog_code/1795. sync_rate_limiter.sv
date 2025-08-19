module sync_rate_limiter #(
    parameter DATA_W = 12,
    parameter MAX_CHANGE = 10
)(
    input clk, rst,
    input [DATA_W-1:0] in_value,
    output reg [DATA_W-1:0] out_value
);
    wire [DATA_W-1:0] diff;
    wire [DATA_W-1:0] limited_change;
    
    assign diff = (in_value > out_value) ? 
                 (in_value - out_value) : (out_value - in_value);
    
    assign limited_change = (diff > MAX_CHANGE) ? MAX_CHANGE : diff;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_value <= 0;
        end else begin
            if (in_value > out_value)
                out_value <= out_value + limited_change;
            else if (in_value < out_value)
                out_value <= out_value - limited_change;
        end
    end
endmodule