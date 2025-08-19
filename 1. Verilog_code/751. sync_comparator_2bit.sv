module sync_comparator_2bit(
    input wire clk,
    input wire rst_n,  // Active-low reset
    input wire [1:0] data_a,
    input wire [1:0] data_b,
    output reg eq_out,  // Equal
    output reg gt_out,  // Greater than
    output reg lt_out   // Less than
);
    // Registered comparison results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset values
            eq_out <= 1'b0;
            gt_out <= 1'b0;
            lt_out <= 1'b0;
        end else begin
            // Equality comparison
            eq_out <= (data_a == data_b);
            
            // Greater than comparison
            gt_out <= (data_a > data_b);
            
            // Less than comparison
            lt_out <= (data_a < data_b);
        end
    end
endmodule