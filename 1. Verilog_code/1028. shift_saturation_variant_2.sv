//SystemVerilog
module shift_saturation_pipeline #(parameter W=8) (
    input                   clk,
    input                   rst_n,
    input                   in_valid,
    input  signed [W-1:0]   din,
    input         [2:0]     shift,
    output                  out_valid,
    output reg signed [W-1:0] dout
);

    // Stage 1: Compute shift_overflow and shift result (move registers after combination logic)
    wire shift_overflow_comb;
    wire signed [W-1:0] shift_result_comb;
    wire                stage1_valid_comb;

    assign shift_overflow_comb = (shift >= W[2:0]);
    assign shift_result_comb   = (shift_overflow_comb) ? {W{1'b0}} : (din >>> shift);
    assign stage1_valid_comb   = in_valid;

    // Stage 2: Register results
    reg signed [W-1:0] dout_stage2;
    reg                valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2  <= {W{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            dout_stage2  <= shift_result_comb;
            valid_stage2 <= stage1_valid_comb;
        end
    end

    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= {W{1'b0}};
        else
            dout <= dout_stage2;
    end

    assign out_valid = valid_stage2;

endmodule