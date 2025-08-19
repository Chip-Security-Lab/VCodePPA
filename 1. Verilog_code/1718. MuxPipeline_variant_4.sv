//SystemVerilog
module MuxPipeline #(parameter W=16) (
    input clk,
    input [3:0][W-1:0] ch,
    input [1:0] sel,
    output reg [W-1:0] dout_reg
);

// Buffer registers for high fanout signals
reg [3:0][W-1:0] ch_buf;
reg [1:0] sel_buf;

// LUT-based selection logic
reg [W-1:0] lut_out;
reg [W-1:0] stage;

// Input buffering stage
always @(posedge clk) begin
    ch_buf <= ch;
    sel_buf <= sel;
end

// LUT implementation for 4:1 mux with buffered inputs
always @(*) begin
    case(sel_buf)
        2'b00: lut_out = ch_buf[0];
        2'b01: lut_out = ch_buf[1];
        2'b10: lut_out = ch_buf[2];
        2'b11: lut_out = ch_buf[3];
        default: lut_out = {W{1'b0}};
    endcase
end

// Pipeline stage
always @(posedge clk) begin
    stage <= lut_out;
    dout_reg <= stage;
end

endmodule