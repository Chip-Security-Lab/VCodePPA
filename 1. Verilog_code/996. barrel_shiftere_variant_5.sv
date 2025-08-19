//SystemVerilog
module barrel_shifter(
    input  [15:0] din,
    input  [3:0]  shamt,
    input         dir,              // Direction: 0=right, 1=left
    output [15:0] dout
);
    wire [15:0] stage1_out;
    wire [15:0] stage2_out;
    wire [15:0] stage3_out;
    wire [15:0] stage4_out;

    // Stage 1: shift by 1
    barrel_shift_stage #(
        .WIDTH(16),
        .SHIFT_AMOUNT(1)
    ) u_stage1 (
        .data_in(din),
        .shift_en(shamt[0]),
        .dir(dir),
        .data_out(stage1_out)
    );

    // Stage 2: shift by 2
    barrel_shift_stage #(
        .WIDTH(16),
        .SHIFT_AMOUNT(2)
    ) u_stage2 (
        .data_in(stage1_out),
        .shift_en(shamt[1]),
        .dir(dir),
        .data_out(stage2_out)
    );

    // Stage 3: shift by 4
    barrel_shift_stage #(
        .WIDTH(16),
        .SHIFT_AMOUNT(4)
    ) u_stage3 (
        .data_in(stage2_out),
        .shift_en(shamt[2]),
        .dir(dir),
        .data_out(stage3_out)
    );

    // Stage 4: shift by 8
    barrel_shift_stage #(
        .WIDTH(16),
        .SHIFT_AMOUNT(8)
    ) u_stage4 (
        .data_in(stage3_out),
        .shift_en(shamt[3]),
        .dir(dir),
        .data_out(stage4_out)
    );

    assign dout = stage4_out;

endmodule

module barrel_shift_stage #(
    parameter WIDTH = 16,
    parameter SHIFT_AMOUNT = 1
)(
    input  [WIDTH-1:0] data_in,
    input              shift_en,
    input              dir, // 0=right, 1=left
    output [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] shifted;

    always @(*) begin
        if (shift_en) begin
            if (dir) begin
                // Left rotate
                shifted = {data_in[WIDTH-SHIFT_AMOUNT-1:0], data_in[WIDTH-1:WIDTH-SHIFT_AMOUNT]};
            end else begin
                // Right rotate
                shifted = {data_in[SHIFT_AMOUNT-1:0], data_in[WIDTH-1:SHIFT_AMOUNT]};
            end
        end else begin
            shifted = data_in;
        end
    end

    assign data_out = shifted;
endmodule