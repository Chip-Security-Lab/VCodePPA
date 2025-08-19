//SystemVerilog
module shift_bidir_cycl #(parameter WIDTH=8) (
    input clk,
    input dir,
    input en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

reg [WIDTH-1:0] shift_reg;

// 8-bit borrow subtractor module declaration
wire [WIDTH-1:0] left_shifted;
wire [WIDTH-1:0] right_shifted;

// Borrow subtractor for right shift (WIDTH-1 down to 1)
wire [WIDTH-2:0] right_shift_sub;
wire [WIDTH-2:0] right_borrow;
genvar i;
generate
    for (i = 0; i < WIDTH-1; i = i + 1) begin : right_borrow_subtractor
        borrow_subtractor_1bit u_borrow_sub_right (
            .minuend(data_in[i+1]),
            .subtrahend(1'b0),
            .borrow_in(1'b0),
            .diff(right_shift_sub[i]),
            .borrow_out(right_borrow[i])
        );
    end
endgenerate
assign right_shifted = {data_in[0], right_shift_sub};

// Borrow subtractor for left shift (WIDTH-2 down to 0)
wire [WIDTH-2:0] left_shift_sub;
wire [WIDTH-2:0] left_borrow;
generate
    for (i = 0; i < WIDTH-1; i = i + 1) begin : left_borrow_subtractor
        borrow_subtractor_1bit u_borrow_sub_left (
            .minuend(data_in[i]),
            .subtrahend(1'b0),
            .borrow_in(1'b0),
            .diff(left_shift_sub[i]),
            .borrow_out(left_borrow[i])
        );
    end
endgenerate
assign left_shifted = {left_shift_sub, data_in[WIDTH-1]};

always @(posedge clk) begin
    if (en) begin
        shift_reg <= dir ? right_shifted : left_shifted;
    end
end

assign data_out = shift_reg;

endmodule

// 1-bit borrow subtractor: diff = minuend - subtrahend - borrow_in
module borrow_subtractor_1bit (
    input minuend,
    input subtrahend,
    input borrow_in,
    output diff,
    output borrow_out
);
    assign diff = minuend ^ subtrahend ^ borrow_in;
    assign borrow_out = (~minuend & subtrahend) | ((~minuend | subtrahend) & borrow_in);
endmodule