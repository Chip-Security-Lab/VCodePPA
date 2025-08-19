//SystemVerilog
module RstInitMux #(parameter DW=8) (
    input                   clk,
    input                   rst,
    input                   start,
    input  [2:0]            sel,
    input  [7:0][DW-1:0]    din,
    output reg [DW-1:0]     dout,
    output reg              valid
);

    // Stage 1: Latch inputs and sel
    reg [2:0]               sel_stage1;
    reg [7:0][DW-1:0]       din_stage1;
    reg                     rst_stage1;
    reg                     valid_stage1;

    always @(posedge clk) begin
        if (rst) begin
            sel_stage1   <= 3'd0;
            din_stage1   <= {8{ {DW{1'b0}} }};
            rst_stage1   <= 1'b1;
            valid_stage1 <= 1'b0;
        end else if (start) begin
            sel_stage1   <= sel;
            din_stage1   <= din;
            rst_stage1   <= rst;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Pipeline sel and rst, break out din data
    reg [2:0]               sel_stage2;
    reg                     rst_stage2;
    reg                     valid_stage2;
    reg [DW-1:0]            din_mux_stage2;

    always @(posedge clk) begin
        if (rst) begin
            sel_stage2      <= 3'd0;
            rst_stage2      <= 1'b1;
            valid_stage2    <= 1'b0;
            din_mux_stage2  <= {DW{1'b0}};
        end else if (valid_stage1) begin
            sel_stage2      <= sel_stage1;
            rst_stage2      <= rst_stage1;
            valid_stage2    <= 1'b1;
            din_mux_stage2  <= din_stage1[sel_stage1];
        end else begin
            valid_stage2    <= 1'b0;
        end
    end

    // Stage 3: MUX select or reset value
    reg [DW-1:0]            dout_stage3;
    reg                     valid_stage3;

    always @(posedge clk) begin
        if (rst) begin
            dout_stage3   <= {DW{1'b0}};
            valid_stage3  <= 1'b0;
        end else if (valid_stage2) begin
            if (rst_stage2)
                dout_stage3 <= din_stage1[0];
            else
                dout_stage3 <= din_mux_stage2;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Stage 4: Output register
    always @(posedge clk) begin
        if (rst) begin
            dout  <= {DW{1'b0}};
            valid <= 1'b0;
        end else begin
            dout  <= dout_stage3;
            valid <= valid_stage3;
        end
    end

endmodule