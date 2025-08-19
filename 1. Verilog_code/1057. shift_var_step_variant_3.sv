//SystemVerilog
module shift_var_step #(parameter WIDTH=8) (
    input clk,
    input rst,
    input [$clog2(WIDTH)-1:0] step,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);

    // Stage 1: Register input signals
    reg [WIDTH-1:0] din_stage1;
    reg [$clog2(WIDTH)-1:0] step_stage1;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_stage1 <= {WIDTH{1'b0}};
            step_stage1 <= {($clog2(WIDTH)){1'b0}};
        end else begin
            din_stage1 <= din;
            step_stage1 <= step;
        end
    end

    // Stage 2: Partial shift (lower half of step)
    localparam STEP_MSB = $clog2(WIDTH)-1;
    localparam STEP_MID = STEP_MSB/2;
    reg [WIDTH-1:0] shift_stage2;
    reg [$clog2(WIDTH)-1:0] step_stage2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_stage2 <= {WIDTH{1'b0}};
            step_stage2 <= {($clog2(WIDTH)){1'b0}};
        end else begin
            shift_stage2 <= din_stage1 << step_stage1[STEP_MID-1:0];
            step_stage2 <= step_stage1;
        end
    end

    // Stage 3: Final shift (upper half of step)
    wire [WIDTH-1:0] dout_internal;
    assign dout_internal = shift_stage2 << step_stage2[STEP_MSB:STEP_MID];

    reg [WIDTH-1:0] dout_stage3;
    always @(posedge clk or posedge rst) begin
        if (rst)
            dout_stage3 <= {WIDTH{1'b0}};
        else
            dout_stage3 <= dout_internal;
    end

    assign dout = dout_stage3;

endmodule