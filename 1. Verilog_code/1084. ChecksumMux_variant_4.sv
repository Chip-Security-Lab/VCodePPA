//SystemVerilog
module ChecksumMux #(parameter DW=8) (
    input                    clk,
    input                    rst_n,
    input      [3:0][DW-1:0] din,
    input      [1:0]         sel,
    input                    in_valid,
    output reg [DW+3:0]      out,
    output reg               out_valid
);

// Stage 1: Mux selection
reg [DW-1:0]      data_stage1;
reg [1:0]         sel_stage1;
reg               valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage1  <= {DW{1'b0}};
        sel_stage1   <= 2'b00;
        valid_stage1 <= 1'b0;
    end else begin
        data_stage1  <= din[sel];
        sel_stage1   <= sel;
        valid_stage1 <= in_valid;
    end
end

// Stage 2: Parity calculation and output concatenation
reg               parity_stage2;
reg [DW-1:0]      data_stage2;
reg [1:0]         sel_stage2;
reg               valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_stage2 <= 1'b0;
        data_stage2   <= {DW{1'b0}};
        sel_stage2    <= 2'b00;
        valid_stage2  <= 1'b0;
    end else begin
        parity_stage2 <= ^data_stage1;
        data_stage2   <= data_stage1;
        sel_stage2    <= sel_stage1;
        valid_stage2  <= valid_stage1;
    end
end

// Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out       <= {(DW+4){1'b0}};
        out_valid <= 1'b0;
    end else begin
        out       <= {parity_stage2, data_stage2, sel_stage2};
        out_valid <= valid_stage2;
    end
end

endmodule