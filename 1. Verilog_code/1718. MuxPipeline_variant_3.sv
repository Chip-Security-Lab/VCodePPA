//SystemVerilog
// Mux stage module
module MuxStage #(parameter W=16) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] dout
);

always @(posedge clk) begin
    dout <= din;
end

endmodule

// Mux selector module
module MuxSelector #(parameter W=16) (
    input [3:0][W-1:0] ch,
    input [1:0] sel,
    output [W-1:0] dout
);

assign dout = ch[sel];

endmodule

// Top level pipeline module
module MuxPipeline #(parameter W=16) (
    input clk,
    input [3:0][W-1:0] ch,
    input [1:0] sel,
    output [W-1:0] dout_reg
);

wire [W-1:0] mux_out;
wire [W-1:0] stage1_out;
wire [W-1:0] stage2_out;

MuxSelector #(.W(W)) mux_inst (
    .ch(ch),
    .sel(sel),
    .dout(mux_out)
);

MuxStage #(.W(W)) stage1 (
    .clk(clk),
    .din(mux_out),
    .dout(stage1_out)
);

MuxStage #(.W(W)) stage2 (
    .clk(clk),
    .din(stage1_out),
    .dout(stage2_out)
);

MuxStage #(.W(W)) stage3 (
    .clk(clk),
    .din(stage2_out),
    .dout(dout_reg)
);

endmodule