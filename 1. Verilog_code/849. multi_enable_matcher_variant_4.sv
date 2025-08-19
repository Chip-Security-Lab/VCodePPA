//SystemVerilog
module multi_enable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input en_capture, en_compare,
    output reg match
);
    reg [DW-1:0] stored_data;
    reg en_compare_r;
    wire compare_result;
    
    // Capture data when enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stored_data <= {DW{1'b0}};
        end else if (en_capture) begin
            stored_data <= data;
        end
    end
    
    // Register the enable signal for comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_compare_r <= 1'b0;
        end else begin
            en_compare_r <= en_compare;
        end
    end
    
    // Move comparison logic before the register
    assign compare_result = (stored_data == pattern);
    
    // Register the comparison result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match <= 1'b0;
        end else if (en_compare_r) begin
            match <= compare_result;
        end
    end
endmodule