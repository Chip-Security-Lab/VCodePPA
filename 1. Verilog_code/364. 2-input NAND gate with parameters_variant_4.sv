//SystemVerilog
module borrow_lookahead_subtractor_8bit (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [7:0]   minuend,
    input  wire [7:0]   subtrahend,
    input  wire         bin,   // initial borrow in
    output wire [7:0]   difference,
    output wire         bout   // final borrow out
);

    // Stage 1: Generate/Propagate computation (Boolean algebra simplified)
    reg [7:0] borrow_generate_stage1;
    reg [7:0] borrow_propagate_stage1;
    reg       bin_latched_stage1;
    reg [7:0] minuend_latched_stage1;
    reg [7:0] subtrahend_latched_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            borrow_generate_stage1   <= 8'd0;
            borrow_propagate_stage1  <= 8'd0;
            bin_latched_stage1       <= 1'b0;
            minuend_latched_stage1   <= 8'd0;
            subtrahend_latched_stage1<= 8'd0;
        end else begin
            // Simplified: G = ~A & B, P = ~A | B
            borrow_generate_stage1  <= (~minuend) & subtrahend;
            borrow_propagate_stage1 <= (~minuend) | subtrahend;
            bin_latched_stage1      <= bin;
            minuend_latched_stage1  <= minuend;
            subtrahend_latched_stage1 <= subtrahend;
        end
    end

    // Stage 2: Borrow chain calculation (using simplified expressions)
    reg [7:0] borrow_chain_stage2;
    reg [7:0] borrow_generate_stage2;
    reg [7:0] borrow_propagate_stage2;
    reg       bin_latched_stage2;
    reg [7:0] minuend_latched_stage2;
    reg [7:0] subtrahend_latched_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            borrow_chain_stage2         <= 8'd0;
            borrow_generate_stage2      <= 8'd0;
            borrow_propagate_stage2     <= 8'd0;
            bin_latched_stage2          <= 1'b0;
            minuend_latched_stage2      <= 8'd0;
            subtrahend_latched_stage2   <= 8'd0;
        end else begin
            borrow_generate_stage2     <= borrow_generate_stage1;
            borrow_propagate_stage2    <= borrow_propagate_stage1;
            bin_latched_stage2         <= bin_latched_stage1;
            minuend_latched_stage2     <= minuend_latched_stage1;
            subtrahend_latched_stage2  <= subtrahend_latched_stage1;
            // Lookahead Borrow Chain using simplified propagate
            borrow_chain_stage2[0] <= borrow_generate_stage1[0] | (borrow_propagate_stage1[0] & bin_latched_stage1);
            borrow_chain_stage2[1] <= borrow_generate_stage1[1] | (borrow_propagate_stage1[1] & borrow_chain_stage2[0]);
            borrow_chain_stage2[2] <= borrow_generate_stage1[2] | (borrow_propagate_stage1[2] & borrow_chain_stage2[1]);
            borrow_chain_stage2[3] <= borrow_generate_stage1[3] | (borrow_propagate_stage1[3] & borrow_chain_stage2[2]);
            borrow_chain_stage2[4] <= borrow_generate_stage1[4] | (borrow_propagate_stage1[4] & borrow_chain_stage2[3]);
            borrow_chain_stage2[5] <= borrow_generate_stage1[5] | (borrow_propagate_stage1[5] & borrow_chain_stage2[4]);
            borrow_chain_stage2[6] <= borrow_generate_stage1[6] | (borrow_propagate_stage1[6] & borrow_chain_stage2[5]);
            borrow_chain_stage2[7] <= borrow_generate_stage1[7] | (borrow_propagate_stage1[7] & borrow_chain_stage2[6]);
        end
    end

    // Stage 3: Difference calculation
    reg [7:0] difference_stage3;
    reg       bout_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            difference_stage3 <= 8'd0;
            bout_stage3       <= 1'b0;
        end else begin
            difference_stage3[0] <= minuend_latched_stage2[0] ^ subtrahend_latched_stage2[0] ^ bin_latched_stage2;
            difference_stage3[1] <= minuend_latched_stage2[1] ^ subtrahend_latched_stage2[1] ^ borrow_chain_stage2[0];
            difference_stage3[2] <= minuend_latched_stage2[2] ^ subtrahend_latched_stage2[2] ^ borrow_chain_stage2[1];
            difference_stage3[3] <= minuend_latched_stage2[3] ^ subtrahend_latched_stage2[3] ^ borrow_chain_stage2[2];
            difference_stage3[4] <= minuend_latched_stage2[4] ^ subtrahend_latched_stage2[4] ^ borrow_chain_stage2[3];
            difference_stage3[5] <= minuend_latched_stage2[5] ^ subtrahend_latched_stage2[5] ^ borrow_chain_stage2[4];
            difference_stage3[6] <= minuend_latched_stage2[6] ^ subtrahend_latched_stage2[6] ^ borrow_chain_stage2[5];
            difference_stage3[7] <= minuend_latched_stage2[7] ^ subtrahend_latched_stage2[7] ^ borrow_chain_stage2[6];
            bout_stage3         <= borrow_chain_stage2[7];
        end
    end

    assign difference = difference_stage3;
    assign bout       = bout_stage3;

endmodule