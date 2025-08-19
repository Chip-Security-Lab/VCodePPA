//SystemVerilog
module RegEnMux_Pipelined #(
    parameter DW = 8
)(
    input                  clk,
    input                  rst_n,
    input                  en,
    input        [1:0]     sel,
    input  [3:0][DW-1:0]   din,
    output reg             dout_valid,
    output reg [DW-1:0]    dout
);

    // Stage 1: Register inputs and valid
    reg                    en_stage1;
    reg  [1:0]             sel_stage1;
    reg  [3:0][DW-1:0]     din_stage1;
    reg                    valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_stage1    <= 1'b0;
            sel_stage1   <= 2'b0;
            din_stage1   <= {4{ {DW{1'b0}} }};
            valid_stage1 <= 1'b0;
        end else begin
            en_stage1    <= en;
            sel_stage1   <= sel;
            din_stage1   <= din;
            valid_stage1 <= en;
        end
    end

    // Stage 2: Optimized mux selection
    reg  [DW-1:0]          mux_out_stage2;
    reg                    valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out_stage2 <= {DW{1'b0}};
            valid_stage2   <= 1'b0;
        end else begin
            case (sel_stage1)
                2'b00: mux_out_stage2 <= din_stage1[0];
                2'b01: mux_out_stage2 <= din_stage1[1];
                2'b10: mux_out_stage2 <= din_stage1[2];
                2'b11: mux_out_stage2 <= din_stage1[3];
                default: mux_out_stage2 <= {DW{1'b0}};
            endcase
            valid_stage2   <= valid_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout       <= {DW{1'b0}};
            dout_valid <= 1'b0;
        end else begin
            dout       <= mux_out_stage2;
            dout_valid <= valid_stage2;
        end
    end

endmodule