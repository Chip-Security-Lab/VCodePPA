//SystemVerilog
module shift_dynamic_cfg #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire [1:0]          cfg_mode, // 00-hold, 01-left, 10-right, 11-load
    input  wire [WIDTH-1:0]    cfg_data,
    output reg  [WIDTH-1:0]    dout
);

wire        mode_hold   = ~cfg_mode[1] & ~cfg_mode[0];
wire        mode_left   = ~cfg_mode[1] &  cfg_mode[0];
wire        mode_right  =  cfg_mode[1] & ~cfg_mode[0];
wire        mode_load   =  cfg_mode[1] &  cfg_mode[0];

wire [WIDTH-1:0] shift_left_result  = {dout[WIDTH-2:0], 1'b0};
wire [WIDTH-1:0] shift_right_result = {1'b0, dout[WIDTH-1:1]};

wire [WIDTH-1:0] dout_next_left   = mode_left  ? shift_left_result  : {WIDTH{1'b0}};
wire [WIDTH-1:0] dout_next_right  = mode_right ? shift_right_result : {WIDTH{1'b0}};
wire [WIDTH-1:0] dout_next_load   = mode_load  ? cfg_data           : {WIDTH{1'b0}};
wire [WIDTH-1:0] dout_next_hold   = mode_hold  ? dout               : {WIDTH{1'b0}};

wire [WIDTH-1:0] dout_next = dout_next_left | dout_next_right | dout_next_load | dout_next_hold;

always @(posedge clk) begin
    dout <= dout_next;
end

endmodule