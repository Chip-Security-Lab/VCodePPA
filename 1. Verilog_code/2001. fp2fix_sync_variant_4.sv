//SystemVerilog
module fp2fix_sync #(
    parameter Q = 8
)(
    input clk,
    input rst,
    input [31:0] fp,
    output reg [30:0] fixed
);

    // Stage 1: Buffer fp input and its fields to reduce fanout
    reg [31:0] fp_buf;
    reg [31:0] fp_buf2;

    // Stage 2: Buffer mant_wire, exp_sub_q_wire, and b0
    reg sign_reg_stage1;
    reg [7:0] exp_reg_stage1;
    reg [23:0] mant_reg_stage1;
    reg [7:0] exp_sub_q_reg_stage1;

    reg sign_reg_stage2;
    reg [7:0] exp_reg_stage2;
    reg [23:0] mant_reg_stage2;
    reg [7:0] exp_sub_q_reg_stage2;

    reg [30:0] shifted_mant_reg;
    reg [30:0] shifted_neg_mant_reg;

    // Fanout buffer for mant_wire
    reg [23:0] mant_buf1;
    reg [23:0] mant_buf2;

    // Fanout buffer for exp_sub_q_wire
    reg [7:0] exp_sub_q_buf1;
    reg [7:0] exp_sub_q_buf2;

    // Fanout buffer for fp (b0 equivalent)
    reg [31:0] fp_b0_buf1;
    reg [31:0] fp_b0_buf2;

    // Internal combinational signals for intermediate logic
    wire sign_wire_stage1;
    wire [7:0] exp_wire_stage1;
    wire [23:0] mant_wire_stage1;
    wire [7:0] exp_sub_q_wire_stage1;

    // Stage 1: Buffer fp (b0) to reduce fanout from input
    always @(posedge clk) begin
        if (rst) begin
            fp_buf <= 32'b0;
            fp_buf2 <= 32'b0;
        end else begin
            fp_buf <= fp;
            fp_buf2 <= fp_buf;
        end
    end

    // Stage 2: Extract fields from buffered fp and buffer further for fanout reduction
    assign sign_wire_stage1 = fp_buf2[31];
    assign exp_wire_stage1 = fp_buf2[30:23] - 127;
    assign mant_wire_stage1 = {1'b1, fp_buf2[22:0]};
    assign exp_sub_q_wire_stage1 = exp_wire_stage1 - Q;

    always @(posedge clk) begin
        if (rst) begin
            sign_reg_stage1 <= 1'b0;
            exp_reg_stage1 <= 8'b0;
            mant_reg_stage1 <= 24'b0;
            exp_sub_q_reg_stage1 <= 8'b0;
        end else begin
            sign_reg_stage1 <= sign_wire_stage1;
            exp_reg_stage1 <= exp_wire_stage1;
            mant_reg_stage1 <= mant_wire_stage1;
            exp_sub_q_reg_stage1 <= exp_sub_q_wire_stage1;
        end
    end

    // Stage 3: Buffer mant_wire, exp_sub_q_wire for high fanout signals
    always @(posedge clk) begin
        if (rst) begin
            mant_buf1 <= 24'b0;
            mant_buf2 <= 24'b0;
            exp_sub_q_buf1 <= 8'b0;
            exp_sub_q_buf2 <= 8'b0;
            fp_b0_buf1 <= 32'b0;
            fp_b0_buf2 <= 32'b0;
        end else begin
            mant_buf1 <= mant_reg_stage1;
            mant_buf2 <= mant_buf1;
            exp_sub_q_buf1 <= exp_sub_q_reg_stage1;
            exp_sub_q_buf2 <= exp_sub_q_buf1;
            fp_b0_buf1 <= fp_buf2;
            fp_b0_buf2 <= fp_b0_buf1;
        end
    end

    // Stage 4: Register signals for timing balance
    always @(posedge clk) begin
        if (rst) begin
            sign_reg_stage2 <= 1'b0;
            exp_reg_stage2 <= 8'b0;
            mant_reg_stage2 <= 24'b0;
            exp_sub_q_reg_stage2 <= 8'b0;
        end else begin
            sign_reg_stage2 <= sign_reg_stage1;
            exp_reg_stage2 <= exp_reg_stage1;
            mant_reg_stage2 <= mant_buf2;
            exp_sub_q_reg_stage2 <= exp_sub_q_buf2;
        end
    end

    // Stage 5: Shift operation using buffered signals
    always @(posedge clk) begin
        if (rst) begin
            shifted_mant_reg <= 31'b0;
            shifted_neg_mant_reg <= 31'b0;
        end else begin
            shifted_mant_reg <= mant_reg_stage2 << exp_sub_q_reg_stage2;
            shifted_neg_mant_reg <= (~mant_reg_stage2 + 1'b1) << exp_sub_q_reg_stage2;
        end
    end

    // Stage 6: Output selection
    always @(posedge clk) begin
        if (rst) begin
            fixed <= 31'b0;
        end else begin
            fixed <= sign_reg_stage2 ? shifted_neg_mant_reg : shifted_mant_reg;
        end
    end

endmodule