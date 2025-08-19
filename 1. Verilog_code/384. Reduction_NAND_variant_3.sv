//SystemVerilog
module Reduction_NAND(
    input  wire        clk,          // Pipeline clock
    input  wire        rst_n,        // Active-low synchronous reset
    input  wire [7:0]  vec,          // 8-bit input vector
    output wire        nand_result   // Final NAND reduction output
);

    // Pipeline Stage 1: Register input vector for timing closure
    reg [7:0] vec_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            vec_reg <= 8'b0;
        else
            vec_reg <= vec;
    end

    // Lookup Table for 4-input AND reduction (16 entries)
    reg and4_lut [0:15];
    initial begin
        and4_lut[ 0] = 1'b0; and4_lut[ 1] = 1'b0; and4_lut[ 2] = 1'b0; and4_lut[ 3] = 1'b0;
        and4_lut[ 4] = 1'b0; and4_lut[ 5] = 1'b0; and4_lut[ 6] = 1'b0; and4_lut[ 7] = 1'b0;
        and4_lut[ 8] = 1'b0; and4_lut[ 9] = 1'b0; and4_lut[10] = 1'b0; and4_lut[11] = 1'b0;
        and4_lut[12] = 1'b0; and4_lut[13] = 1'b0; and4_lut[14] = 1'b0; and4_lut[15] = 1'b1;
    end

    // Pipeline Stage 2: Use LUT for 4-input AND reduction
    reg [1:0] and4_stage;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            and4_stage <= 2'b0;
        else begin
            and4_stage[0] <= and4_lut[vec_reg[3:0]];
            and4_stage[1] <= and4_lut[vec_reg[7:4]];
        end
    end

    // Lookup Table for 2-input AND reduction (4 entries)
    reg and2_lut [0:3];
    initial begin
        and2_lut[0] = 1'b0;
        and2_lut[1] = 1'b0;
        and2_lut[2] = 1'b0;
        and2_lut[3] = 1'b1;
    end

    // Pipeline Stage 3: Use LUT for 2-input AND reduction
    reg and_final_stage;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            and_final_stage <= 1'b0;
        else
            and_final_stage <= and2_lut[and4_stage];
    end

    // Pipeline Stage 4: Output NAND (inversion)
    reg nand_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            nand_out_reg <= 1'b1;
        else
            nand_out_reg <= ~and_final_stage;
    end

    // Output assignment
    assign nand_result = nand_out_reg;

endmodule