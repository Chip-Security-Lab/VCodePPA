//SystemVerilog
module jittered_clock_rng (
    input wire main_clk,
    input wire reset,
    input wire [7:0] jitter_value,
    output reg [15:0] random_out
);
    // Stage 1: Counter and comparison
    reg [7:0] counter_stage1;
    reg [7:0] jitter_value_stage1;
    reg valid_stage1;

    // Stage 2: Capture bit logic
    reg capture_bit_stage2;
    reg capture_bit_next_stage2;
    reg [7:0] counter_stage2;
    reg [15:0] random_out_stage2;
    reg valid_stage2;

    // Stage 3: Random output update
    reg [15:0] random_out_stage3;
    reg valid_stage3;

    // Pipeline flush control
    reg flush_pipeline;

    // Stage 1: Counter increment and jitter value capture
    always @(posedge main_clk) begin
        if (reset) begin
            counter_stage1 <= 8'h01;
            jitter_value_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
            flush_pipeline <= 1'b1;
        end else begin
            counter_stage1 <= counter_stage1 + 1'b1;
            jitter_value_stage1 <= jitter_value;
            valid_stage1 <= 1'b1;
            flush_pipeline <= 1'b0;
        end
    end

    // Stage 2: Capture bit logic and intermediate random_out
    always @(posedge main_clk) begin
        if (reset || flush_pipeline) begin
            capture_bit_stage2 <= 1'b0;
            capture_bit_next_stage2 <= 1'b0;
            counter_stage2 <= 8'd0;
            random_out_stage2 <= 16'h1234;
            valid_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            // Use case statement for control flow
            case (counter_stage1 == jitter_value_stage1)
                1'b1: begin
                    capture_bit_next_stage2 <= ~capture_bit_stage2;
                end
                1'b0: begin
                    capture_bit_next_stage2 <= capture_bit_stage2;
                end
            endcase

            capture_bit_stage2 <= capture_bit_next_stage2;

            case (capture_bit_next_stage2)
                1'b1: random_out_stage2 <= {random_out_stage2[14:0], counter_stage1[0] ^ random_out_stage2[15]};
                1'b0: random_out_stage2 <= random_out_stage2;
            endcase

            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge main_clk) begin
        if (reset || flush_pipeline) begin
            random_out_stage3 <= 16'h1234;
            valid_stage3 <= 1'b0;
        end else begin
            random_out_stage3 <= random_out_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output logic: register output with valid
    always @(posedge main_clk) begin
        if (reset) begin
            random_out <= 16'h1234;
        end else if (valid_stage3) begin
            random_out <= random_out_stage3;
        end
    end

endmodule