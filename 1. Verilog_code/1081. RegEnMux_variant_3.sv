//SystemVerilog
module RegEnMux #(parameter DW=8) (
    input clk,
    input en,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output [DW-1:0] dout
);

reg [DW-1:0] din_reg [3:0];
reg [1:0] sel_reg;
reg en_reg;

wire [3:0] minuend_4b;
wire [3:0] subtrahend_4b;
wire [3:0] diff_4b;
wire [3:0] borrow_chain;
wire borrow_out;

assign minuend_4b    = din_reg[sel_reg][3:0];
assign subtrahend_4b = din_reg[0][3:0];

// 4-bit borrow-lookahead subtractor
assign diff_4b[0] = minuend_4b[0] ^ subtrahend_4b[0];
assign borrow_chain[0] = (~minuend_4b[0] & subtrahend_4b[0]);

assign diff_4b[1] = minuend_4b[1] ^ subtrahend_4b[1] ^ borrow_chain[0];
assign borrow_chain[1] = ((~minuend_4b[1] & subtrahend_4b[1]) | ((~minuend_4b[1] | subtrahend_4b[1]) & borrow_chain[0]));

assign diff_4b[2] = minuend_4b[2] ^ subtrahend_4b[2] ^ borrow_chain[1];
assign borrow_chain[2] = ((~minuend_4b[2] & subtrahend_4b[2]) | ((~minuend_4b[2] | subtrahend_4b[2]) & borrow_chain[1]));

assign diff_4b[3] = minuend_4b[3] ^ subtrahend_4b[3] ^ borrow_chain[2];
assign borrow_chain[3] = ((~minuend_4b[3] & subtrahend_4b[3]) | ((~minuend_4b[3] | subtrahend_4b[3]) & borrow_chain[2]));

assign borrow_out = borrow_chain[3];

// Output: if en_reg, output subtraction result, else zero
assign dout = en_reg ? {{(DW-4){1'b0}}, diff_4b} : {DW{1'b0}};

always @(posedge clk) begin
    if(en) begin
        din_reg[0] <= din[0];
        din_reg[1] <= din[1];
        din_reg[2] <= din[2];
        din_reg[3] <= din[3];
        sel_reg <= sel;
        en_reg <= 1'b1;
    end else begin
        en_reg <= 1'b0;
    end
end

endmodule