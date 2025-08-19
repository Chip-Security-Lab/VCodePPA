//SystemVerilog
module RegInMux #(
    parameter DW = 8
)(
    input                   clk,
    input       [1:0]       sel,
    input       [3:0][DW-1:0] din,
    output      [DW-1:0]    dout
);

    // Pipeline Stage 1: Input Registering
    reg [DW-1:0] stage1_reg [3:0];

    always @(posedge clk) begin
        stage1_reg[0] <= din[0];
        stage1_reg[1] <= din[1];
        stage1_reg[2] <= din[2];
        stage1_reg[3] <= din[3];
    end

    // Pipeline Stage 2: Multiplexer Output Register
    reg [DW-1:0] stage2_mux_out;

    always @(posedge clk) begin
        case (sel)
            2'd0: stage2_mux_out <= stage1_reg[0];
            2'd1: stage2_mux_out <= stage1_reg[1];
            2'd2: stage2_mux_out <= stage1_reg[2];
            2'd3: stage2_mux_out <= stage1_reg[3];
            default: stage2_mux_out <= {DW{1'b0}};
        endcase
    end

    // Output assignment from final pipeline stage
    assign dout = stage2_mux_out;

endmodule