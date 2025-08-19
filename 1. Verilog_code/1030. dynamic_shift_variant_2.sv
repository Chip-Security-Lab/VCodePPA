//SystemVerilog
module dynamic_shift #(parameter W=8) (
    input clk,
    input [3:0] ctrl, // [1:0]: direction, [3:2]: type
    input [W-1:0] din,
    output reg [W-1:0] dout
);

wire [6:0] minuend;
wire [6:0] subtrahend;
wire [6:0] difference;
wire borrow_out;

assign minuend    = din[6:0];
assign subtrahend = 7'b0000001; // for -1 operation

// 7-bit borrow lookahead subtractor
borrow_lookahead_subtractor_7bit u_borrow_lookahead_subtractor_7bit (
    .a      (minuend),
    .b      (subtrahend),
    .diff   (difference),
    .borrow (borrow_out)
);

// Barrel shifter implementation (mux-based)
function [W-1:0] barrel_shifter_left;
    input [W-1:0] data_in;
    input [3:0]   shift_amt;
    integer i;
    reg [W-1:0] stage0, stage1, stage2;
begin
    // 1-bit shift
    for (i=0; i<W; i=i+1)
        stage0[i] = (shift_amt[0]) ? ((i==0) ? 1'b0 : data_in[i-1]) : data_in[i];
    // 2-bit shift
    for (i=0; i<W; i=i+1)
        stage1[i] = (shift_amt[1]) ? ((i<2) ? 1'b0 : stage0[i-2]) : stage0[i];
    // 4-bit shift
    for (i=0; i<W; i=i+1)
        stage2[i] = (shift_amt[2]) ? ((i<4) ? 1'b0 : stage1[i-4]) : stage1[i];
    barrel_shifter_left = stage2;
end
endfunction

function [W-1:0] barrel_shifter_right;
    input [W-1:0] data_in;
    input [3:0]   shift_amt;
    integer i;
    reg [W-1:0] stage0, stage1, stage2;
begin
    // 1-bit shift
    for (i=0; i<W; i=i+1)
        stage0[i] = (shift_amt[0]) ? ((i==W-1) ? 1'b0 : data_in[i+1]) : data_in[i];
    // 2-bit shift
    for (i=0; i<W; i=i+1)
        stage1[i] = (shift_amt[1]) ? ((i>W-3) ? 1'b0 : stage0[i+2]) : stage0[i];
    // 4-bit shift
    for (i=0; i<W; i=i+1)
        stage2[i] = (shift_amt[2]) ? ((i>W-5) ? 1'b0 : stage1[i+4]) : stage1[i];
    barrel_shifter_right = stage2;
end
endfunction

function [W-1:0] barrel_rotator_left;
    input [W-1:0] data_in;
    input [3:0]   rot_amt;
    reg [W-1:0] temp;
begin
    temp = data_in;
    if (rot_amt[0]) temp = {temp[W-2:0], temp[W-1]};
    if (rot_amt[1]) temp = {temp[W-3:0], temp[W-1:W-2]};
    if (rot_amt[2]) temp = {temp[W-5:0], temp[W-1:W-4]};
    barrel_rotator_left = temp;
end
endfunction

function [W-1:0] barrel_rotator_right;
    input [W-1:0] data_in;
    input [3:0]   rot_amt;
    reg [W-1:0] temp;
begin
    temp = data_in;
    if (rot_amt[0]) temp = {temp[0], temp[W-1:1]};
    if (rot_amt[1]) temp = {temp[1:0], temp[W-1:2]};
    if (rot_amt[2]) temp = {temp[3:0], temp[W-1:4]};
    barrel_rotator_right = temp;
end
endfunction

always @(posedge clk) begin
    case({ctrl[3:2], ctrl[1:0]})
        4'b0000: dout <= barrel_shifter_left(din, 4'd1);                             // Logical left shift by 1
        4'b0001: dout <= {1'b0, difference};                                         // Logical right shift via subtractor
        4'b0010: dout <= {din[6:0], din[7]};                                         // Rotate left by 1 (special case)
        4'b0011: dout <= {din[0], din[7:1]};                                         // Rotate right by 1 (special case)
        default: dout <= {W{1'b0}};
    endcase
end

endmodule

module borrow_lookahead_subtractor_7bit (
    input  [6:0] a,
    input  [6:0] b,
    output [6:0] diff,
    output       borrow
);
    wire [6:0] generate_borrow;
    wire [6:0] propagate_borrow;
    wire [7:0] borrow_chain;

    assign borrow_chain[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 7; i = i + 1) begin : gen_lookahead
            assign generate_borrow[i] = (~a[i]) & b[i];
            assign propagate_borrow[i] = ~(a[i] ^ b[i]);
            assign borrow_chain[i+1] = generate_borrow[i] | (propagate_borrow[i] & borrow_chain[i]);
            assign diff[i] = a[i] ^ b[i] ^ borrow_chain[i];
        end
    endgenerate

    assign borrow = borrow_chain[7];
endmodule