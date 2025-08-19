//SystemVerilog
module reset_status_register(
    input              clk,
    input              global_rst_n,
    input      [5:0]   reset_inputs_n,   // Active low inputs
    input      [5:0]   status_clear,     // Clear individual bits
    output reg [5:0]   reset_status
);

    // Pipeline registers
    reg  [5:0] active_resets_s1, prev_resets_s1;
    reg        valid_s1, flush_s1;

    reg  [5:0] active_resets_s2, prev_resets_s2, reset_edge_s2;
    reg        valid_s2, flush_s2;

    reg  [5:0] reset_status_s3;
    reg        valid_s3, flush_s3;

    // Synchronous flush
    wire pipeline_flush = ~global_rst_n;

    // Stage 1: Input decode and synchronization (optimized)
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            active_resets_s1 <= 6'b0;
            prev_resets_s1   <= 6'b0;
            valid_s1         <= 1'b0;
            flush_s1         <= 1'b1;
        end else begin
            active_resets_s1 <= ~reset_inputs_n;
            prev_resets_s1   <= active_resets_s1;
            valid_s1         <= 1'b1;
            flush_s1         <= 1'b0;
        end
    end

    // Stage 2: Edge detection (optimized)
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            active_resets_s2 <= 6'b0;
            prev_resets_s2   <= 6'b0;
            reset_edge_s2    <= 6'b0;
            valid_s2         <= 1'b0;
            flush_s2         <= 1'b1;
        end else begin
            active_resets_s2 <= active_resets_s1;
            prev_resets_s2   <= prev_resets_s1;
            // Efficient edge detection for all bits at once
            reset_edge_s2    <= active_resets_s1 & ~prev_resets_s1;
            valid_s2         <= valid_s1 & ~flush_s1;
            flush_s2         <= flush_s1;
        end
    end

    // Stage 3: Status register update (optimized)
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            reset_status_s3 <= 6'b0;
            valid_s3        <= 1'b0;
            flush_s3        <= 1'b1;
        end else begin
            // Efficient update: use bitwise logic, range check not needed for fixed width
            reset_status_s3 <= (reset_status | reset_edge_s2) & ~status_clear;
            valid_s3        <= valid_s2 & ~flush_s2;
            flush_s3        <= flush_s2;
        end
    end

    // Output register with optimized control
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            reset_status <= 6'b0;
        end else if (valid_s3 & ~flush_s3) begin
            reset_status <= reset_status_s3;
        end
    end

endmodule