//SystemVerilog
module rng_parkmiller_16(
    input             clk,
    input             rst,
    input             en,
    output reg [31:0] rand_out
);

    // Pipeline registers for breaking the long combinational path
    reg [63:0] mult_result_stage1;
    reg [31:0] rand_out_stage1;
    reg        en_stage1;

    reg [31:0] mod_result_stage2;
    reg        en_stage2;
    reg [31:0] rand_out_stage2;

    //===============================================================
    // Stage 1: Multiplication
    //===============================================================
    always @(posedge clk) begin
        if (rst) begin
            mult_result_stage1 <= 64'd0;
            rand_out_stage1    <= 32'd0;
            en_stage1          <= 1'b0;
        end else begin
            mult_result_stage1 <= rand_out * 32'd16807;
            rand_out_stage1    <= rand_out;
            en_stage1          <= en;
        end
    end

    //===============================================================
    // Stage 2: Modulo operation
    //===============================================================
    always @(posedge clk) begin
        if (rst) begin
            mod_result_stage2 <= 32'd1;
            en_stage2         <= 1'b0;
            rand_out_stage2   <= 32'd1;
        end else begin
            if (en_stage1)
                mod_result_stage2 <= mult_result_stage1 % 32'd2147483647;
            else
                mod_result_stage2 <= rand_out_stage1;
            en_stage2       <= en_stage1;
            rand_out_stage2 <= rand_out_stage1;
        end
    end

    //===============================================================
    // Stage 3: Output register update
    //===============================================================
    always @(posedge clk) begin
        if (rst)
            rand_out <= 32'd1;
        else if (en_stage2)
            rand_out <= mod_result_stage2;
        else
            rand_out <= rand_out_stage2;
    end

endmodule