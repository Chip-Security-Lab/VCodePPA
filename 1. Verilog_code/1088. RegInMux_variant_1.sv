//SystemVerilog
module RegInMux #(parameter DW=8) (
    input                   clk,
    input       [1:0]       sel,
    input       [3:0][DW-1:0] din,
    output reg  [DW-1:0]    dout
);

// First-level buffer registers for high-fanout 'sel' and 'din'
reg [1:0] sel_buf;
reg [3:0][DW-1:0] din_buf;

// Second-level buffer registers for further fanout balancing
reg [1:0] sel_buf_2;
reg [3:0][DW-1:0] din_buf_2;

// Selection signal buffers
reg sel_is_0;
reg sel_is_1;
reg sel_is_2;
reg sel_is_3;

// Pipeline data registers for mux tree
reg [DW-1:0] din_reg_0;
reg [DW-1:0] din_reg_1;
reg [DW-1:0] din_reg_2;
reg [DW-1:0] din_reg_3;

// Buffered mux outputs
reg [DW-1:0] mux_out_0;
reg [DW-1:0] mux_out_1;

// First buffer stage for sel and din
always @(posedge clk) begin
    sel_buf   <= sel;
    din_buf   <= din;
end

// Second buffer stage for sel and din
always @(posedge clk) begin
    sel_buf_2 <= sel_buf;
    din_buf_2 <= din_buf;
end

// Buffer selection signals to reduce fanout and balance path
always @(posedge clk) begin
    sel_is_0 <= (sel_buf_2 == 2'b00);
    sel_is_1 <= (sel_buf_2 == 2'b01);
    sel_is_2 <= (sel_buf_2 == 2'b10);
    sel_is_3 <= (sel_buf_2 == 2'b11);
end

// Buffer data bus to balance path
always @(posedge clk) begin
    din_reg_0 <= din_buf_2[0];
    din_reg_1 <= din_buf_2[1];
    din_reg_2 <= din_buf_2[2];
    din_reg_3 <= din_buf_2[3];
end

// Two-level buffered multiplexer tree
always @(posedge clk) begin
    mux_out_0 <= sel_is_0 ? din_reg_0 : din_reg_1;
    mux_out_1 <= sel_is_2 ? din_reg_2 : din_reg_3;
end

// Output register with balanced selection
always @(posedge clk) begin
    if (sel_is_0 | sel_is_1)
        dout <= mux_out_0;
    else
        dout <= mux_out_1;
end

endmodule