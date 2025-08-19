//SystemVerilog
module bbs_rng (
    input wire clock,
    input wire reset,
    output wire [7:0] random_byte
);
    parameter P = 11;
    parameter Q = 23;
    parameter M = 253; // P * Q

    // Pipeline registers for state and valid signal
    reg [15:0] state_stage0;
    reg [31:0] square_stage1;
    reg [8:0] sum_stage2;
    reg [7:0] state_stage3;
    reg valid_stage0, valid_stage1, valid_stage2, valid_stage3;

    // Output register
    reg [7:0] output_reg;

    // Pipeline flush logic (reset)
    always @(posedge clock) begin
        if (reset) begin
            state_stage0 <= 16'd3;
            valid_stage0 <= 1'b0;
        end else begin
            state_stage0 <= state_stage3; // feedback for next state
            valid_stage0 <= valid_stage3;
        end
    end

    // Stage 1: Square the state
    always @(posedge clock) begin
        if (reset) begin
            square_stage1 <= 32'd0;
            valid_stage1 <= 1'b0;
        end else begin
            square_stage1 <= state_stage0 * state_stage0;
            valid_stage1 <= valid_stage0;
        end
    end

    // Stage 2: Partial modular reduction (sum computation)
    always @(posedge clock) begin
        if (reset) begin
            sum_stage2 <= 9'd0;
            valid_stage2 <= 1'b0;
        end else begin
            sum_stage2 <= square_stage1[7:0] 
                        + square_stage1[15:8] * 3 
                        + square_stage1[23:16] * 9 
                        + square_stage1[31:24] * 27;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Final modular reduction and register state
    always @(posedge clock) begin
        integer i;
        reg [8:0] sum_temp;
        if (reset) begin
            state_stage3 <= 8'd3;
            valid_stage3 <= 1'b0;
        end else begin
            sum_temp = sum_stage2;
            // Sequentially subtract 253 until sum < 253
            for (i = 0; i < 4; i = i + 1) begin
                if (sum_temp >= M)
                    sum_temp = sum_temp - M;
            end
            state_stage3 <= sum_temp[7:0];
            valid_stage3 <= valid_stage2;
        end
    end

    // Output register
    always @(posedge clock) begin
        if (reset)
            output_reg <= 8'd0;
        else if (valid_stage3)
            output_reg <= state_stage3;
    end

    assign random_byte = output_reg;

endmodule