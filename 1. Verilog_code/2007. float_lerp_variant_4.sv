//SystemVerilog
module float_lerp #(parameter MANT=10, parameter EXP=5)(
    input  [MANT+EXP:0] a,
    input  [MANT+EXP:0] b,
    input  [7:0] t,
    output [MANT+EXP:0] c
);

wire [7:0] one_minus_t;
assign one_minus_t = 8'd255 - t;

wire [MANT+EXP:0] diff_ba;
assign diff_ba = b - a;

wire [15:0] t_sq;
wire [23:0] t_cu;
wire [7:0]  t_lin;
wire [15:0] t_sq_div2;
wire [23:0] t_cu_div6;

assign t_lin = t;
assign t_sq = t * t;
assign t_cu = t * t * t;

// Barrel shifter for t_sq_div2 = t_sq >> 1
wire [15:0] t_sq_div2_bs;
barrel_shifter_right #(.WIDTH(16), .SHIFTS(1)) u_bs_t_sq_div2 (
    .data_in(t_sq),
    .shift_amt(1'b1),
    .data_out(t_sq_div2_bs)
);
assign t_sq_div2 = t_sq_div2_bs;

// t_cu_div6 = t_cu / 6
assign t_cu_div6 = t_cu / 6;

// Barrel shifter for (t_sq_div2 >> 8)
wire [15:0] t_sq_div2_shift8;
barrel_shifter_right #(.WIDTH(16), .SHIFTS(8)) u_bs_t_sq_div2_8 (
    .data_in(t_sq_div2),
    .shift_amt(4'd8),
    .data_out(t_sq_div2_shift8)
);

// Barrel shifter for (t_cu_div6 >> 16)
wire [23:0] t_cu_div6_shift16;
barrel_shifter_right #(.WIDTH(24), .SHIFTS(16)) u_bs_t_cu_div6_16 (
    .data_in(t_cu_div6),
    .shift_amt(5'd16),
    .data_out(t_cu_div6_shift16)
);

// Taylor sum: taylor_sum_1 = {8'd0, t_lin} - (t_sq_div2 >> 8)
wire [15:0] taylor_sum_1;
assign taylor_sum_1 = {8'd0, t_lin} - t_sq_div2_shift8;

// Taylor sum: taylor_sum_2 = taylor_sum_1 + (t_cu_div6 >> 16)
wire [15:0] taylor_sum_2;
assign taylor_sum_2 = taylor_sum_1 + t_cu_div6_shift16[15:0];

wire [15:0] taylor_sum;
assign taylor_sum = taylor_sum_2;

// diff_ba_scaled = diff_ba * taylor_sum
wire [MANT+EXP+15:0] diff_ba_scaled;
assign diff_ba_scaled = diff_ba * taylor_sum;

// a_scaled = a << 8 using barrel shifter
wire [MANT+EXP+15:0] a_scaled;
barrel_shifter_left #(.WIDTH(MANT+EXP+16), .SHIFTS(8)) u_bs_a_scaled (
    .data_in({{16{1'b0}}, a}),
    .shift_amt(4'd8),
    .data_out(a_scaled)
);

// lerp_sum = a_scaled + diff_ba_scaled
wire [MANT+EXP+15:0] lerp_sum;
assign lerp_sum = a_scaled + diff_ba_scaled;

// c = lerp_sum >> 8 using barrel shifter
wire [MANT+EXP+15:0] lerp_sum_shift8;
barrel_shifter_right #(.WIDTH(MANT+EXP+16), .SHIFTS(8)) u_bs_lerp_sum_8 (
    .data_in(lerp_sum),
    .shift_amt(4'd8),
    .data_out(lerp_sum_shift8)
);

assign c = lerp_sum_shift8[MANT+EXP:0];

endmodule

// 通用桶形右移
module barrel_shifter_right #(parameter WIDTH=16, parameter SHIFTS=8)(
    input  [WIDTH-1:0] data_in,
    input  [$clog2(SHIFTS+1)-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] stage [0:$clog2(SHIFTS)];
    assign stage[0] = data_in;
    genvar i;
    generate
        for (i = 0; i < $clog2(SHIFTS+1); i = i + 1) begin: shifter
            assign stage[i+1] = shift_amt[i] ? (stage[i] >> (1 << i)) : stage[i];
        end
    endgenerate
    assign data_out = stage[$clog2(SHIFTS+1)];
endmodule

// 通用桶形左移
module barrel_shifter_left #(parameter WIDTH=16, parameter SHIFTS=8)(
    input  [WIDTH-1:0] data_in,
    input  [$clog2(SHIFTS+1)-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] stage [0:$clog2(SHIFTS)];
    assign stage[0] = data_in;
    genvar i;
    generate
        for (i = 0; i < $clog2(SHIFTS+1); i = i + 1) begin: shifter
            assign stage[i+1] = shift_amt[i] ? (stage[i] << (1 << i)) : stage[i];
        end
    endgenerate
    assign data_out = stage[$clog2(SHIFTS+1)];
endmodule