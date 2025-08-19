//SystemVerilog
module UniversalShifter #(parameter WIDTH=8) (
    input clk,
    input [1:0] mode, // 00:hold 01:left 10:right 11:load
    input serial_in,
    input [WIDTH-1:0] parallel_in,
    output reg [WIDTH-1:0] data_reg
);

// Buffer registers for high-fanout mode signals
reg [1:0] mode_buf1, mode_buf2;
wire mode_hold_buf, mode_left_buf, mode_right_buf, mode_load_buf;

// Buffer registers for high-fanout data_reg and next_data_reg
reg [WIDTH-1:0] data_reg_buf1, data_reg_buf2;
reg [WIDTH-1:0] next_data_reg, next_data_reg_buf1, next_data_reg_buf2;

// Buffering mode signal to reduce fanout
always @(posedge clk) begin
    mode_buf1 <= mode;
    mode_buf2 <= mode_buf1;
end

assign mode_hold_buf  = (mode_buf2 == 2'b00);
assign mode_left_buf  = (mode_buf2 == 2'b01);
assign mode_right_buf = (mode_buf2 == 2'b10);
assign mode_load_buf  = (mode_buf2 == 2'b11);

// Buffering data_reg to reduce fanout
always @(posedge clk) begin
    data_reg_buf1 <= data_reg;
    data_reg_buf2 <= data_reg_buf1;
end

wire [WIDTH-1:0] left_shifted_buf;
wire [WIDTH-1:0] right_shifted_buf;

assign left_shifted_buf  = {data_reg_buf2[WIDTH-2:0], serial_in};
assign right_shifted_buf = {serial_in, data_reg_buf2[WIDTH-1:1]};

// Path-balanced logic for next_data_reg with buffered control signals
always @* begin
    casez ({mode_load_buf, mode_right_buf, mode_left_buf})
        3'b100: next_data_reg = parallel_in;
        3'b010: next_data_reg = right_shifted_buf;
        3'b001: next_data_reg = left_shifted_buf;
        default: next_data_reg = data_reg_buf2;
    endcase
end

// Buffer next_data_reg to reduce fanout
always @(posedge clk) begin
    next_data_reg_buf1 <= next_data_reg;
    next_data_reg_buf2 <= next_data_reg_buf1;
end

always @(posedge clk) begin
    data_reg <= next_data_reg_buf2;
end

endmodule