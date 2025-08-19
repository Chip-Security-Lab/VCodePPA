//SystemVerilog
module MuxSyncReg #(parameter DW=8, AW=3) (
    input                   clk,
    input                   rst_n,
    input                   valid_in,
    input                   flush,
    input  [AW-1:0]         sel,
    input  [2**AW*DW-1:0]   data_in,
    output [DW-1:0]         data_out,
    output                  valid_out
);

    // Stage 1: Register select and valid
    reg [AW-1:0]   sel_stage1;
    reg            valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage1   <= {AW{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (flush) begin
            sel_stage1   <= {AW{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (valid_in) begin
            sel_stage1   <= sel;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Mux operation and valid register
    reg [DW-1:0]   mux_out_stage2;
    reg            valid_stage2;

    wire [DW-1:0]  mux_out_stage1;
    assign mux_out_stage1 = data_in[sel_stage1*DW +: DW];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out_stage2 <= {DW{1'b0}};
            valid_stage2   <= 1'b0;
        end else if (flush) begin
            mux_out_stage2 <= {DW{1'b0}};
            valid_stage2   <= 1'b0;
        end else if (valid_stage1) begin
            mux_out_stage2 <= mux_out_stage1;
            valid_stage2   <= 1'b1;
        end else begin
            valid_stage2   <= 1'b0;
        end
    end

    assign data_out  = mux_out_stage2;
    assign valid_out = valid_stage2;

endmodule