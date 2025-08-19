//SystemVerilog
module sync_rate_limiter #(
    parameter DATA_W = 12,
    parameter MAX_CHANGE = 10
)(
    input clk, rst,
    input [DATA_W-1:0] in_value,
    output reg [DATA_W-1:0] out_value
);
    reg [DATA_W-1:0] in_value_reg;
    wire [DATA_W-1:0] diff;
    wire [DATA_W-1:0] limited_change;
    wire [DATA_W-1:0] next_out_value;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_value_reg <= 0;
        end else begin
            in_value_reg <= in_value;
        end
    end
    
    assign diff = (in_value_reg > out_value) ? 
                 (in_value_reg - out_value) : (out_value - in_value_reg);
    
    assign limited_change = (diff > MAX_CHANGE) ? MAX_CHANGE : diff;
    
    assign next_out_value = (in_value_reg > out_value) ? 
                          (out_value + limited_change) : 
                          (in_value_reg < out_value) ? 
                          (out_value - limited_change) : 
                          out_value;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_value <= 0;
        end else begin
            out_value <= next_out_value;
        end
    end
endmodule