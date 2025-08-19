//SystemVerilog
module RegInMux_Pipelined #(
    parameter DW = 8
)(
    input                  clk,
    input                  rst_n,
    input                  valid_in,
    input        [1:0]     sel_in,
    input  [3:0][DW-1:0]   din_in,
    output                 valid_out,
    output [DW-1:0]        dout
);

    // Stage 1: Register inputs
    reg                    valid_stage1;
    reg          [1:0]     sel_stage1;
    reg   [3:0][DW-1:0]    din_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            sel_stage1   <= 2'b00;
            din_stage1   <= {4{ {DW{1'b0}} }};
        end else begin
            valid_stage1 <= valid_in;
            sel_stage1   <= sel_in;
            din_stage1   <= din_in;
        end
    end

    // Stage 2: Multiplexing
    reg                    valid_stage2;
    reg         [DW-1:0]   dout_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            dout_stage2  <= {DW{1'b0}};
        end else begin
            valid_stage2 <= valid_stage1;
            case (sel_stage1)
                2'd0: dout_stage2 <= din_stage1[0];
                2'd1: dout_stage2 <= din_stage1[1];
                2'd2: dout_stage2 <= din_stage1[2];
                2'd3: dout_stage2 <= din_stage1[3];
                default: dout_stage2 <= {DW{1'b0}};
            endcase
        end
    end

    assign valid_out = valid_stage2;
    assign dout     = dout_stage2;

endmodule