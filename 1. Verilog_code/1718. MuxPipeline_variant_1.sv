//SystemVerilog
module MuxPipeline #(parameter W=16) (
    input clk,
    input [3:0][W-1:0] ch,
    input [1:0] sel,
    output reg [W-1:0] dout_reg
);

    // First pipeline stage - pre-mux selection
    reg [1:0] sel_reg;
    reg [3:0][W-1:0] ch_reg;
    always @(posedge clk) begin
        sel_reg <= sel;
        ch_reg <= ch;
    end

    // Mux stage with registered inputs
    wire [W-1:0] mux_out;
    Mux4to1 #(.W(W)) mux_inst (
        .ch(ch_reg),
        .sel(sel_reg),
        .out(mux_out)
    );

    // Second pipeline stage - post-mux
    reg [W-1:0] stage;
    always @(posedge clk) begin
        stage <= mux_out;
        dout_reg <= stage;
    end

endmodule

module Mux4to1 #(parameter W=16) (
    input [3:0][W-1:0] ch,
    input [1:0] sel,
    output reg [W-1:0] out
);
    always @(*) begin
        case(sel)
            2'b00: out = ch[0];
            2'b01: out = ch[1];
            2'b10: out = ch[2];
            2'b11: out = ch[3];
            default: out = {W{1'bx}};
        endcase
    end
endmodule