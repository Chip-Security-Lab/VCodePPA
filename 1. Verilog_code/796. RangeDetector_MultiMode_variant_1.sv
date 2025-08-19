//SystemVerilog
module RangeDetector_MultiMode #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [1:0] mode,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg flag
);
    // Pre-compute all comparison results in combinational logic
    wire greater_equal = (data_in >= threshold);
    wire less_equal = (data_in <= threshold);
    wire not_equal = (data_in != threshold);
    wire equal = (data_in == threshold);
    
    // Register comparison selection based on mode
    reg comparison_result;
    
    // Mode decoder logic block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comparison_result <= 1'b0;
        end else begin
            case(mode)
                2'b00: comparison_result <= greater_equal;
                2'b01: comparison_result <= less_equal;
                2'b10: comparison_result <= not_equal;
                2'b11: comparison_result <= equal;
            endcase
        end
    end
    
    // Output register block for maintaining proper output timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flag <= 1'b0;
        end else begin
            flag <= comparison_result;
        end
    end
endmodule