//SystemVerilog
module rng_hash_15(
    input             clk,
    input             rst_n,
    input             enable,
    output reg [7:0]  out_v
);

    // Pipeline stage 1: latch input and current state
    reg  [7:0]  out_v_stage1;
    reg         enable_stage1;
    reg         valid_stage1;

    // Pipeline stage 2: feedback bit calculation
    reg         feedback_bit_stage2;
    reg  [7:0]  out_v_stage2;
    reg         enable_stage2;
    reg         valid_stage2;

    // Pipeline stage 3: update output
    reg  [7:0]  out_v_stage3;
    reg         valid_stage3;

    // Pipeline flush logic
    wire        flush;
    assign      flush = ~rst_n;

    // Stage 1: Register current out_v and enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_v_stage1   <= 8'hD2;
            enable_stage1  <= 1'b0;
            valid_stage1   <= 1'b0;
        end else begin
            if (enable) begin
                out_v_stage1   <= out_v;
                enable_stage1  <= 1'b1;
                valid_stage1   <= 1'b1;
            end else begin
                enable_stage1  <= 1'b0;
                valid_stage1   <= 1'b0;
            end
        end
    end

    // Stage 2: Calculate feedback bit
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_v_stage2      <= 8'hD2;
            feedback_bit_stage2 <= 1'b0;
            enable_stage2     <= 1'b0;
            valid_stage2      <= 1'b0;
        end else if (flush) begin
            out_v_stage2      <= 8'hD2;
            feedback_bit_stage2 <= 1'b0;
            enable_stage2     <= 1'b0;
            valid_stage2      <= 1'b0;
        end else begin
            out_v_stage2      <= out_v_stage1;
            feedback_bit_stage2 <= out_v_stage1[7] ^ out_v_stage1[5] ^ out_v_stage1[1] ^ out_v_stage1[0];
            enable_stage2     <= enable_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Stage 3: Shift and update output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_v_stage3   <= 8'hD2;
            valid_stage3   <= 1'b0;
        end else if (flush) begin
            out_v_stage3   <= 8'hD2;
            valid_stage3   <= 1'b0;
        end else begin
            if (enable_stage2 && valid_stage2) begin
                out_v_stage3 <= {out_v_stage2[6:0], feedback_bit_stage2};
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end

    // Output register (final stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_v <= 8'hD2;
        end else if (valid_stage3) begin
            out_v <= out_v_stage3;
        end
    end

endmodule