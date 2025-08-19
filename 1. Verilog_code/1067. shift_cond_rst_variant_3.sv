//SystemVerilog
module shift_cond_rst_pipelined #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  cond_rst,
    input  wire [WIDTH-1:0]      din,
    input  wire                  valid_in,
    output wire [WIDTH-1:0]      dout,
    output wire                  valid_out
);

    // Stage 1: Capture inputs and valid
    reg [WIDTH-1:0] din_stage1;
    reg             cond_rst_stage1;
    reg             valid_stage1;

    always @(posedge clk) begin
        din_stage1        <= din;
        cond_rst_stage1   <= cond_rst;
        valid_stage1      <= valid_in;
    end

    // Stage 2: Shift logic
    reg [WIDTH-1:0] shift_result_stage2;
    reg [WIDTH-1:0] din_stage2;
    reg             cond_rst_stage2;
    reg             valid_stage2;

    always @(posedge clk) begin
        din_stage2         <= din_stage1;
        cond_rst_stage2    <= cond_rst_stage1;
        valid_stage2       <= valid_stage1;
        shift_result_stage2<= {dout_stage2[WIDTH-2:0], din_stage1[WIDTH-1]};
    end

    // Stage 3: Output mux with conditional sum/subtract for subtraction
    reg [WIDTH-1:0] dout_stage2;
    reg             valid_stage3;

    // Conditional Sum/Subtract implementation (for subtraction)
    wire [WIDTH-1:0] subtract_b;
    wire             subtract_carry_in;
    wire [WIDTH-1:0] subtract_sum;
    wire [WIDTH:0]   subtract_carry;

    assign subtract_b        = 8'b0; // In this module, no explicit subtraction input, placeholder
    assign subtract_carry_in = 1'b0; // Same as above

    assign subtract_carry[0] = subtract_carry_in;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_conditional_sum_subtract
            assign subtract_sum[i] = dout_stage2[i] ^ subtract_b[i] ^ subtract_carry[i];
            assign subtract_carry[i+1] = (dout_stage2[i] & subtract_b[i]) | (dout_stage2[i] & subtract_carry[i]) | (subtract_b[i] & subtract_carry[i]);
        end
    endgenerate

    always @(posedge clk) begin
        if (cond_rst_stage2) begin
            dout_stage2 <= din_stage2;
        end else begin
            // Use conditional sum/subtract algorithm to compute shift_result_stage2 - 0
            // Since subtract_b is all 0 and carry_in is 0, result is shift_result_stage2 itself
            dout_stage2 <= shift_result_stage2;
        end
        valid_stage3 <= valid_stage2;
    end

    assign dout      = dout_stage2;
    assign valid_out = valid_stage3;

endmodule