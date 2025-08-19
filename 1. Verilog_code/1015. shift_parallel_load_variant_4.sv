//SystemVerilog
module shift_parallel_load_pipelined #(parameter DEPTH=4) (
    input             clk,
    input             rst_n,
    input             load,
    input      [7:0]  pdata,
    input             valid_in,
    output reg [7:0]  sout,
    output            valid_out
);

// Stage 1: Load or shift operation
reg  [7:0] shift_reg_stage1;
reg        valid_stage1;

// Stage 2: Output register
reg  [7:0] shift_reg_stage2;
reg        valid_stage2;

// Flush logic
wire flush;
assign flush = ~rst_n;

// Stage 1: Shift or load operation and valid propagation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg_stage1 <= 8'b0;
        valid_stage1     <= 1'b0;
    end else if (flush) begin
        shift_reg_stage1 <= 8'b0;
        valid_stage1     <= 1'b0;
    end else if (valid_in) begin
        shift_reg_stage1 <= load ? pdata : {shift_reg_stage1[6:0], 1'b0};
        valid_stage1     <= 1'b1;
    end else begin
        valid_stage1     <= 1'b0;
    end
end

// Stage 2: Output register and valid propagation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg_stage2 <= 8'b0;
        valid_stage2     <= 1'b0;
    end else if (flush) begin
        shift_reg_stage2 <= 8'b0;
        valid_stage2     <= 1'b0;
    end else if (valid_stage1) begin
        shift_reg_stage2 <= shift_reg_stage1;
        valid_stage2     <= valid_stage1;
    end else begin
        valid_stage2     <= 1'b0;
    end
end

// Assign outputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sout <= 8'b0;
    else if (flush)
        sout <= 8'b0;
    else if (valid_stage2)
        sout <= shift_reg_stage2;
end

assign valid_out = valid_stage2;

endmodule