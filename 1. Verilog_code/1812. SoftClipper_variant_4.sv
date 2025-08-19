//SystemVerilog
module SoftClipper #(parameter W=8, THRESH=8'hF0) (
    input [W-1:0] din,
    output [W-1:0] dout
);

    wire [W-1:0] pos_clipped;
    wire [W-1:0] neg_clipped;
    wire [W-1:0] final_out;

    PosClipper #(.W(W), .THRESH(THRESH)) pos_clip (
        .din(din),
        .dout(pos_clipped)
    );

    NegClipper #(.W(W), .THRESH(THRESH)) neg_clip (
        .din(din),
        .dout(neg_clipped)
    );

    OutputSelector #(.W(W)) out_sel (
        .din(din),
        .pos_clipped(pos_clipped),
        .neg_clipped(neg_clipped),
        .dout(final_out)
    );

    assign dout = final_out;

endmodule

module PosClipper #(parameter W=8, THRESH=8'hF0) (
    input [W-1:0] din,
    output [W-1:0] dout
);
    wire [W-1:0] diff;
    wire [W-1:0] half_diff;
    
    assign diff = din - THRESH;
    assign half_diff = diff >> 1;
    assign dout = (din > THRESH) ? THRESH + half_diff : din;
endmodule

module NegClipper #(parameter W=8, THRESH=8'hF0) (
    input [W-1:0] din,
    output [W-1:0] dout
);
    wire [W-1:0] diff;
    wire [W-1:0] half_diff;
    
    assign diff = -THRESH - din;
    assign half_diff = diff >> 1;
    assign dout = (din < -THRESH) ? -THRESH - half_diff : din;
endmodule

module OutputSelector #(parameter W=8) (
    input [W-1:0] din,
    input [W-1:0] pos_clipped,
    input [W-1:0] neg_clipped,
    output [W-1:0] dout
);
    assign dout = (din > 0) ? pos_clipped : neg_clipped;
endmodule