//SystemVerilog
module shift_cycl_right_pipeline #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      din,
    input  [2:0]            shift_amt,
    output [WIDTH-1:0]      dout
);

    // Stage 1: Register input signals
    reg [WIDTH-1:0]         din_stage1;
    reg [2:0]               shift_amt_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1        <= {WIDTH{1'b0}};
            shift_amt_stage1  <= 3'd0;
        end else begin
            din_stage1        <= din;
            shift_amt_stage1  <= shift_amt;
        end
    end

    // Stage 2: Compute (WIDTH - shift_amt) using conditional inversion subtractor
    reg [2:0]               minuend_stage2;
    reg [2:0]               subtrahend_stage2;
    reg [2:0]               shift_amt_complement_stage2;
    reg                     subtract_carry_in_stage2;
    reg [2:0]               shift_amt_stage2;
    reg [WIDTH-1:0]         din_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            minuend_stage2              <= 3'd0;
            subtrahend_stage2           <= 3'd0;
            shift_amt_complement_stage2 <= 3'd0;
            subtract_carry_in_stage2    <= 1'b0;
            shift_amt_stage2            <= 3'd0;
            din_stage2                  <= {WIDTH{1'b0}};
        end else begin
            minuend_stage2              <= 3'd8; // WIDTH = 8
            subtrahend_stage2           <= shift_amt_stage1;
            shift_amt_complement_stage2 <= ~shift_amt_stage1;
            subtract_carry_in_stage2    <= 1'b1;
            shift_amt_stage2            <= shift_amt_stage1;
            din_stage2                  <= din_stage1;
        end
    end

    // Stage 3: Full Adder Logic (Combinational)
    wire [2:0] fa_sum_stage3;
    wire [2:0] fa_carry_stage3;
    wire [2:0] minuend_pipe;
    wire [2:0] shift_amt_complement_pipe;
    wire       subtract_carry_in_pipe;

    assign minuend_pipe              = minuend_stage2;
    assign shift_amt_complement_pipe = shift_amt_complement_stage2;
    assign subtract_carry_in_pipe    = subtract_carry_in_stage2;

    // Bit 0
    assign {fa_carry_stage3[0], fa_sum_stage3[0]} = minuend_pipe[0] + shift_amt_complement_pipe[0] + subtract_carry_in_pipe;
    // Bit 1
    assign {fa_carry_stage3[1], fa_sum_stage3[1]} = minuend_pipe[1] + shift_amt_complement_pipe[1] + fa_carry_stage3[0];
    // Bit 2
    assign {fa_carry_stage3[2], fa_sum_stage3[2]} = minuend_pipe[2] + shift_amt_complement_pipe[2] + fa_carry_stage3[1];

    wire [2:0] shift_amt_inv_stage3;
    assign shift_amt_inv_stage3 = {fa_sum_stage3[2], fa_sum_stage3[1], fa_sum_stage3[0]};

    // Stage 4: Register shift amounts and input data for final shift operation
    reg [2:0] shift_amt_stage4;
    reg [2:0] shift_amt_inv_stage4;
    reg [WIDTH-1:0] din_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_amt_stage4      <= 3'd0;
            shift_amt_inv_stage4  <= 3'd0;
            din_stage4            <= {WIDTH{1'b0}};
        end else begin
            shift_amt_stage4      <= shift_amt_stage2;
            shift_amt_inv_stage4  <= shift_amt_inv_stage3;
            din_stage4            <= din_stage2;
        end
    end

    // Stage 5: Final shift operation
    reg [WIDTH-1:0] dout_stage5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage5 <= {WIDTH{1'b0}};
        end else begin
            dout_stage5 <= (din_stage4 >> shift_amt_stage4) | (din_stage4 << shift_amt_inv_stage4);
        end
    end

    assign dout = dout_stage5;

endmodule