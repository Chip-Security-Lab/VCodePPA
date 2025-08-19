//SystemVerilog
module fibonacci_lfsr_generator (
    input wire clk_i,
    input wire arst_n_i,
    output wire [31:0] random_o
);
    // Stage 1: Tap extraction
    reg [31:0] shift_register_stage1;
    reg tap31_stage1, tap21_stage1, tap1_stage1, tap0_stage1;

    // Stage 2: Partial XORs
    reg xor1_stage2, xor2_stage2;

    // Stage 3: Final feedback XOR
    reg feedback_stage3;

    // Stage 4: Shift register update
    reg [31:0] shift_register_stage4;

    // Stage 1: Tap extraction
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i) begin
            shift_register_stage1 <= 32'h1;
            tap31_stage1 <= 1'b0;
            tap21_stage1 <= 1'b0;
            tap1_stage1  <= 1'b0;
            tap0_stage1  <= 1'b0;
        end else if (arst_n_i && clk_i) begin
            shift_register_stage1 <= shift_register_stage4;
            tap31_stage1 <= shift_register_stage4[31];
            tap21_stage1 <= shift_register_stage4[21];
            tap1_stage1  <= shift_register_stage4[1];
            tap0_stage1  <= shift_register_stage4[0];
        end
    end

    // Stage 2: Partial XORs
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i) begin
            xor1_stage2 <= 1'b0;
            xor2_stage2 <= 1'b0;
        end else if (arst_n_i && clk_i) begin
            xor1_stage2 <= tap31_stage1 ^ tap21_stage1;
            xor2_stage2 <= tap1_stage1  ^ tap0_stage1;
        end
    end

    // Stage 3: Final feedback XOR
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i) begin
            feedback_stage3 <= 1'b0;
        end else if (arst_n_i && clk_i) begin
            feedback_stage3 <= xor1_stage2 ^ xor2_stage2;
        end
    end

    // Stage 4: Shift register update
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i) begin
            shift_register_stage4 <= 32'h1;
        end else if (arst_n_i && clk_i) begin
            shift_register_stage4 <= {shift_register_stage1[30:0], feedback_stage3};
        end
    end

    assign random_o = shift_register_stage4;

endmodule