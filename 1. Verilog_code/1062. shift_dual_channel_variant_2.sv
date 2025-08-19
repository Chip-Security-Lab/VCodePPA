//SystemVerilog
module shift_dual_channel #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] left_out,
    output wire [WIDTH-1:0] right_out
);

    // Pipeline Stage 1: Input Register
    reg [WIDTH-1:0] din_stage1;
    always @(*) begin
        din_stage1 = din;
    end

    // Pipeline Stage 2: Shift Left Preparation
    reg [WIDTH-1:0] left_shift_stage2;
    reg             left_valid_stage2;
    always @(*) begin
        left_shift_stage2 = din_stage1 << 1;
        left_valid_stage2 = (din_stage1 < {1'b1, {WIDTH-1{1'b0}}});
    end

    // Pipeline Stage 2: Shift Right Preparation
    reg [WIDTH-1:0] right_shift_stage2;
    reg             right_valid_stage2;
    always @(*) begin
        right_shift_stage2 = din_stage1 >> 1;
        right_valid_stage2 = (din_stage1 > 0);
    end

    // Pipeline Stage 3: Output Selection
    reg [WIDTH-1:0] left_out_stage3;
    reg [WIDTH-1:0] right_out_stage3;
    always @(*) begin
        left_out_stage3  = left_valid_stage2  ? left_shift_stage2  : {WIDTH{1'b0}};
        right_out_stage3 = right_valid_stage2 ? right_shift_stage2 : {WIDTH{1'b0}};
    end

    // Output assignments
    assign left_out  = left_out_stage3;
    assign right_out = right_out_stage3;

endmodule