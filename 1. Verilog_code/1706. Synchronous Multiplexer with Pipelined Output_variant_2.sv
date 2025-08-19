//SystemVerilog
module mux_4to1(
    input [15:0] in1, in2, in3, in4,
    input [1:0] sel,
    output reg [15:0] mux_out
);
    always @(*) begin
        case(sel)
            2'b00: mux_out = in1;
            2'b01: mux_out = in2;
            2'b10: mux_out = in3;
            2'b11: mux_out = in4;
            default: mux_out = 16'h0;
        endcase
    end
endmodule

module pipeline_reg(
    input clk, resetn,
    input [15:0] data_in,
    output reg [15:0] data_out
);
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            data_out <= 16'h0;
        end else begin
            data_out <= data_in;
        end
    end
endmodule

module pipeline_mux(
    input clk, resetn,
    input [15:0] in1, in2, in3, in4,
    input [1:0] sel,
    output [15:0] pipe_out
);
    wire [15:0] mux_out;
    wire [15:0] stage1_out;

    mux_4to1 mux_inst(
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4),
        .sel(sel),
        .mux_out(mux_out)
    );

    pipeline_reg stage1_reg(
        .clk(clk),
        .resetn(resetn),
        .data_in(mux_out),
        .data_out(stage1_out)
    );

    pipeline_reg stage2_reg(
        .clk(clk),
        .resetn(resetn),
        .data_in(stage1_out),
        .data_out(pipe_out)
    );
endmodule