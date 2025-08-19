//SystemVerilog
module variable_step_shift_pipeline #(
    parameter W = 8
)(
    input                  clk,
    input                  rst_n,
    input                  valid_in,
    input  [1:0]           step_in,
    input  [W-1:0]         din_in,
    output                 valid_out,
    output [W-1:0]         dout_out
);

// Stage 1: Register inputs
reg        valid_stage1;
reg [1:0]  step_stage1;
reg [W-1:0] din_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1 <= 1'b0;
        step_stage1  <= 2'b00;
        din_stage1   <= {W{1'b0}};
    end else begin
        valid_stage1 <= valid_in;
        step_stage1  <= step_in;
        din_stage1   <= din_in;
    end
end

// Stage 2: Optimized Shift Calculation
reg        valid_stage2;
reg [W-1:0] shift_result_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage2        <= 1'b0;
        shift_result_stage2 <= {W{1'b0}};
    end else begin
        valid_stage2 <= valid_stage1;
        case (step_stage1)
            2'b00: shift_result_stage2 <= din_stage1;
            2'b01: shift_result_stage2 <= din_stage1 << 1;
            2'b10: shift_result_stage2 <= din_stage1 << 2;
            default: shift_result_stage2 <= (W > 4) ? {din_stage1[W-5:0], 4'b0000} : {W{1'b0}};
        endcase
    end
end

// Stage 3: Output register (pipeline balancing)
reg        valid_stage3;
reg [W-1:0] dout_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage3 <= 1'b0;
        dout_stage3  <= {W{1'b0}};
    end else begin
        valid_stage3 <= valid_stage2;
        dout_stage3  <= shift_result_stage2;
    end
end

assign valid_out = valid_stage3;
assign dout_out  = dout_stage3;

endmodule