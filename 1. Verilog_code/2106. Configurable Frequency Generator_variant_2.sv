//SystemVerilog
module config_freq_gen(
    input  wire        master_clk,
    input  wire        rstn,
    input  wire [7:0]  freq_sel,
    output reg         out_clk
);

    // Stage 1: Pipeline registers
    reg [7:0]   counter_stage1;
    reg [7:0]   freq_sel_stage1;
    reg         valid_stage1;

    // Stage 2: Pipeline registers
    reg [7:0]   counter_stage2;
    reg [7:0]   freq_sel_stage2;
    reg         cmp_result_stage2;
    reg         out_clk_stage2;
    reg         valid_stage2;

    // Stage 3: Output register
    reg         valid_stage3;

    // Pipeline flush and valid control
    wire        flush;
    assign flush = ~rstn;

    // --- Path balancing and logic restructuring ---

    // Stage 1: Register freq_sel and counter, valid pipeline
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            counter_stage1    <= 8'd0;
            freq_sel_stage1   <= 8'd0;
            valid_stage1      <= 1'b0;
        end else begin
            counter_stage1    <= counter_stage2;
            freq_sel_stage1   <= freq_sel;
            valid_stage1      <= 1'b1;
        end
    end

    // Stage 2: Register and balance logic with precomputed values
    reg        cmp_result_stage1;
    reg [7:0]  next_counter_stage2;
    reg        toggle_clk_stage2;

    always @(*) begin
        // Precompute comparison and next counter value to balance logic paths
        cmp_result_stage1   = (counter_stage1 >= freq_sel_stage1);
        next_counter_stage2 = cmp_result_stage1 ? 8'd0 : (counter_stage1 + 8'd1);
        toggle_clk_stage2   = cmp_result_stage1;
    end

    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            counter_stage2      <= 8'd0;
            freq_sel_stage2     <= 8'd0;
            cmp_result_stage2   <= 1'b0;
            out_clk_stage2      <= 1'b0;
            valid_stage2        <= 1'b0;
        end else if (flush) begin
            counter_stage2      <= 8'd0;
            freq_sel_stage2     <= 8'd0;
            cmp_result_stage2   <= 1'b0;
            out_clk_stage2      <= 1'b0;
            valid_stage2        <= 1'b0;
        end else begin
            counter_stage2      <= next_counter_stage2;
            freq_sel_stage2     <= freq_sel_stage1;
            cmp_result_stage2   <= cmp_result_stage1;
            valid_stage2        <= valid_stage1;

            // Toggle output clock if comparator is true, else keep unchanged
            out_clk_stage2      <= toggle_clk_stage2 ? ~out_clk_stage2 : out_clk_stage2;
        end
    end

    // Stage 3: Output register (for timing closure)
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            out_clk         <= 1'b0;
            valid_stage3    <= 1'b0;
        end else if (flush) begin
            out_clk         <= 1'b0;
            valid_stage3    <= 1'b0;
        end else if (valid_stage2) begin
            out_clk         <= out_clk_stage2;
            valid_stage3    <= valid_stage2;
        end
    end

endmodule