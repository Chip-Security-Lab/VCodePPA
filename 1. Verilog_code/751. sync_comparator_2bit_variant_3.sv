//SystemVerilog
module sync_comparator_2bit_valid_ready(
    input wire clk,
    input wire rst_n,  // Active-low reset
    input wire [1:0] data_a,
    input wire [1:0] data_b,
    output reg eq_out,  // Equal
    output reg gt_out,  // Greater than
    output reg lt_out,   // Less than
    input wire valid,    // Valid signal
    output reg ready     // Ready signal
);
    // Internal signals
    reg processing;       // Indicates if processing is ongoing

    // Registered comparison results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset values
            eq_out <= 1'b0;
            gt_out <= 1'b0;
            lt_out <= 1'b0;
            ready <= 1'b1; // Ready to accept new data
            processing <= 1'b0;
        end else begin
            if (valid && ready) begin
                // Perform comparisons when valid and ready
                eq_out <= (data_a == data_b);
                gt_out <= (data_a > data_b);
                lt_out <= (data_a < data_b);
                processing <= 1'b1; // Set processing flag
                ready <= 1'b0; // Not ready until processing is done
            end else if (!valid) begin
                // If valid is low, set ready high
                ready <= 1'b1;
                processing <= 1'b0; // Clear processing flag
            end
            
            // Reset outputs if processing is done
            if (processing) begin
                ready <= 1'b1; // Set ready high after processing
                processing <= 1'b0; // Clear processing flag
            end
        end
    end
endmodule