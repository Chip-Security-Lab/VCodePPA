//SystemVerilog
module RstInitMux #(parameter DW=8) (
    input               clk,
    input               rst,
    input               start,
    input       [2:0]   sel,
    input       [7:0][DW-1:0] din,
    output reg  [DW-1:0] dout,
    output reg          valid_out
);

// Stage 1: valid signal pipeline
reg valid_stage1;

// Stage 2: Multiplexing and output register
reg [DW-1:0] muxout_stage2;
reg          valid_stage2;

// Move register after the mux logic for forward retiming
wire [DW-1:0] muxout_comb;
assign muxout_comb = rst ? din[0] : din[sel];

always @(posedge clk) begin
    if (rst) begin
        valid_stage1 <= 1'b0;
    end else begin
        valid_stage1 <= start;
    end
end

always @(posedge clk) begin
    if (rst) begin
        muxout_stage2 <= {DW{1'b0}};
        valid_stage2  <= 1'b0;
    end else begin
        if (valid_stage1) begin
            muxout_stage2 <= muxout_comb;
            valid_stage2  <= 1'b1;
        end else begin
            muxout_stage2 <= muxout_stage2;
            valid_stage2  <= 1'b0;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        dout      <= {DW{1'b0}};
        valid_out <= 1'b0;
    end else begin
        dout      <= muxout_stage2;
        valid_out <= valid_stage2;
    end
end

endmodule