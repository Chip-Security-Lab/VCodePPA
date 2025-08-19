//SystemVerilog
module rng_parkmiller_16(
    input             clk,
    input             rst,
    input             en,
    output reg [31:0] rand_out
);

    // Pipeline stage registers
    reg [31:0] rand_reg_stage0;
    reg        en_reg_stage0;
    reg        valid_stage0;

    reg [63:0] mul_result_stage1;
    reg        en_reg_stage1;
    reg        valid_stage1;

    reg [31:0] mod_result_stage2;
    reg        valid_stage2;

    // Pipeline control logic
    wire       stage0_valid_in;
    wire       stage1_valid_in;
    wire       stage2_valid_in;

    assign stage0_valid_in = en;

    // Stage 0: Register input and valid
    always @(posedge clk) begin
        if (rst) begin
            rand_reg_stage0 <= 32'd1;
            en_reg_stage0   <= 1'b0;
            valid_stage0    <= 1'b0;
        end else begin
            rand_reg_stage0 <= rand_out;
            en_reg_stage0   <= en;
            valid_stage0    <= stage0_valid_in;
        end
    end

    // Stage 1: Multiplication
    always @(posedge clk) begin
        if (rst) begin
            mul_result_stage1 <= 64'd0;
            en_reg_stage1     <= 1'b0;
            valid_stage1      <= 1'b0;
        end else begin
            mul_result_stage1 <= en_reg_stage0 ? rand_reg_stage0 * 32'd16807 : {32'd0, rand_reg_stage0};
            en_reg_stage1     <= en_reg_stage0;
            valid_stage1      <= valid_stage0;
        end
    end

    // Stage 2: Modulo operation
    always @(posedge clk) begin
        if (rst) begin
            mod_result_stage2 <= 32'd1;
            valid_stage2      <= 1'b0;
        end else begin
            mod_result_stage2 <= en_reg_stage1 ? mul_result_stage1 % 32'd2147483647 : mul_result_stage1[31:0];
            valid_stage2      <= valid_stage1;
        end
    end

    // Output register
    always @(posedge clk) begin
        if (rst) begin
            rand_out <= 32'd1;
        end else if (valid_stage2) begin
            rand_out <= mod_result_stage2;
        end
    end

endmodule