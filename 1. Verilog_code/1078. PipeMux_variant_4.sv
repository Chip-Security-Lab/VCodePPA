//SystemVerilog
module PipeMux #(
    parameter DW = 8,
    parameter STAGES = 4  // Increased pipeline depth for higher frequency
) (
    input wire clk,
    input wire rst,
    input wire [3:0] sel,
    input wire [(16*DW)-1:0] din,
    input wire valid_in,
    input wire flush,
    output wire [DW-1:0] dout,
    output wire valid_out
);

    // Pipeline stage registers
    reg [DW-1:0] data_stage1;
    reg         valid_stage1;

    reg [DW-1:0] data_stage2;
    reg         valid_stage2;

    reg [DW-1:0] data_stage3;
    reg         valid_stage3;

    reg [DW-1:0] data_stage4;
    reg         valid_stage4;

    // Stage 1: Mux index decode (lightweight)
    reg  [3:0]  sel_stage1;
    reg         valid_sel_stage1;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sel_stage1        <= 4'd0;
            valid_sel_stage1  <= 1'b0;
        end else if (flush) begin
            sel_stage1        <= 4'd0;
            valid_sel_stage1  <= 1'b0;
        end else if (valid_in) begin
            sel_stage1        <= sel;
            valid_sel_stage1  <= 1'b1;
        end else begin
            valid_sel_stage1  <= 1'b0;
        end
    end

    // Stage 2: Mux input latch
    reg [(16*DW)-1:0] din_stage2;
    reg               valid_din_stage2;
    reg  [3:0]        sel_stage2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_stage2      <= {(16*DW){1'b0}};
            sel_stage2      <= 4'd0;
            valid_din_stage2<= 1'b0;
        end else if (flush) begin
            din_stage2      <= {(16*DW){1'b0}};
            sel_stage2      <= 4'd0;
            valid_din_stage2<= 1'b0;
        end else if (valid_sel_stage1) begin
            din_stage2      <= din;
            sel_stage2      <= sel_stage1;
            valid_din_stage2<= 1'b1;
        end else begin
            valid_din_stage2<= 1'b0;
        end
    end

    // Stage 3: Actual mux operation (was combinational before)
    reg [DW-1:0] mux_data_stage3;
    reg          valid_mux_stage3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mux_data_stage3  <= {DW{1'b0}};
            valid_mux_stage3 <= 1'b0;
        end else if (flush) begin
            mux_data_stage3  <= {DW{1'b0}};
            valid_mux_stage3 <= 1'b0;
        end else if (valid_din_stage2) begin
            if (sel_stage2 < 16)
                mux_data_stage3 <= din_stage2[(sel_stage2*DW) +: DW];
            else
                mux_data_stage3 <= {DW{1'b0}};
            valid_mux_stage3 <= 1'b1;
        end else begin
            valid_mux_stage3 <= 1'b0;
        end
    end

    // Stage 4: Output register stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage4  <= {DW{1'b0}};
            valid_stage4 <= 1'b0;
        end else if (flush) begin
            data_stage4  <= {DW{1'b0}};
            valid_stage4 <= 1'b0;
        end else if (valid_mux_stage3) begin
            data_stage4  <= mux_data_stage3;
            valid_stage4 <= 1'b1;
        end else begin
            valid_stage4 <= 1'b0;
        end
    end

    // Output assignments
    assign dout      = data_stage4;
    assign valid_out = valid_stage4;

endmodule