module barrel_rot_bi_dir (
    input [31:0] data_in,
    input [4:0] shift_val,
    input direction,  // 0-left, 1-right
    output [31:0] data_out
);
wire [31:0] left = (data_in << shift_val) | (data_in >> (32 - shift_val));
wire [31:0] right = (data_in >> shift_val) | (data_in << (32 - shift_val));
assign data_out = direction ? right : left;
endmodule