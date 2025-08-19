//SystemVerilog
module sync_comparator_2bit_req_ack(
    input wire clk,
    input wire rst_n,  // Active-low reset
    input wire [1:0] data_a,
    input wire [1:0] data_b,
    output reg req,     // Request signal
    output reg ack,     // Acknowledge signal
    output reg eq_out,  // Equal
    output reg gt_out,  // Greater than
    output reg lt_out   // Less than
);
    // Intermediate comparison signals
    reg eq_comb, gt_comb, lt_comb;
    reg data_ready; // Internal signal to indicate data is ready for comparison

    // Combinational comparison logic
    always @(*) begin
        // Default assignments
        eq_comb = 1'b0;
        gt_comb = 1'b0;
        lt_comb = 1'b0;
        
        // Priority-based comparison (only one flag will be active)
        if (data_a[1] > data_b[1]) begin
            gt_comb = 1'b1;
        end else if (data_a[1] < data_b[1]) begin
            lt_comb = 1'b1;
        end else begin
            // MSB is equal, check LSB
            if (data_a[0] > data_b[0]) begin
                gt_comb = 1'b1;
            end else if (data_a[0] < data_b[0]) begin
                lt_comb = 1'b1;
            end else begin
                eq_comb = 1'b1;
            end
        end
    end

    // Request and acknowledge logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset values
            req <= 1'b0;
            ack <= 1'b0;
            eq_out <= 1'b0;
            gt_out <= 1'b0;
            lt_out <= 1'b0;
            data_ready <= 1'b0;
        end else begin
            // Generate request signal when data is ready
            req <= 1'b1;
            data_ready <= 1'b1;

            // Process comparison results when acknowledged
            if (ack) begin
                eq_out <= eq_comb;
                gt_out <= gt_comb;
                lt_out <= lt_comb;
                req <= 1'b0; // Clear request after acknowledgment
                ack <= 1'b0; // Clear acknowledge
            end else if (data_ready) begin
                ack <= 1'b1; // Set acknowledge when data is ready
            end
        end
    end
endmodule