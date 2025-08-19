//SystemVerilog
module shift_arith_log_sel #(parameter WIDTH=8) (
    input                   clk,
    input                   rst_n,
    input                   mode, // 0-logical, 1-arithmetic
    input  [WIDTH-1:0]      din,
    input  [2:0]            shift,
    output [WIDTH-1:0]      dout
);

// === Pipeline Stage 1: Shift Calculation ===
wire [WIDTH-1:0] logical_shift_stage1;
wire [WIDTH-1:0] arithmetic_shift_stage1;

assign logical_shift_stage1    = din >> shift;
assign arithmetic_shift_stage1 = $signed(din) >>> shift;

// === Pipeline Stage 2: Registering Shift Results and Mode ===
reg  [WIDTH-1:0] logical_shift_stage2;
reg  [WIDTH-1:0] arithmetic_shift_stage2;
reg              mode_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        logical_shift_stage2     <= {WIDTH{1'b0}};
        arithmetic_shift_stage2  <= {WIDTH{1'b0}};
        mode_stage2              <= 1'b0;
    end else begin
        logical_shift_stage2     <= logical_shift_stage1;
        arithmetic_shift_stage2  <= arithmetic_shift_stage1;
        mode_stage2              <= mode;
    end
end

// === Pipeline Stage 3: Output Selection ===
reg  [WIDTH-1:0] dout_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_stage3 <= {WIDTH{1'b0}};
    end else begin
        dout_stage3 <= mode_stage2 ? arithmetic_shift_stage2 : logical_shift_stage2;
    end
end

assign dout = dout_stage3;

endmodule