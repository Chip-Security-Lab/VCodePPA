//SystemVerilog
module thermometer_to_binary #(
    parameter THERMO_WIDTH = 7
)(
    input  wire                              clk,
    input  wire                              rst_n,
    input  wire [THERMO_WIDTH-1:0]           thermo_in,
    output reg  [$clog2(THERMO_WIDTH+1)-1:0] binary_out
);

    // Stage 0: Input Register
    reg [THERMO_WIDTH-1:0] thermo_stage0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            thermo_stage0 <= {THERMO_WIDTH{1'b0}};
        else
            thermo_stage0 <= thermo_in;
    end

    // Stage 1: 2-bit group addition pipeline
    reg [THERMO_WIDTH-1:0] sum_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage1 <= {THERMO_WIDTH{1'b0}};
        end else begin
            sum_stage1[0] <= thermo_stage0[0];
            sum_stage1[1] <= thermo_stage0[0] + thermo_stage0[1];
            sum_stage1[2] <= thermo_stage0[2];
            sum_stage1[3] <= thermo_stage0[2] + thermo_stage0[3];
            sum_stage1[4] <= thermo_stage0[4];
            sum_stage1[5] <= thermo_stage0[4] + thermo_stage0[5];
            sum_stage1[6] <= thermo_stage0[6];
        end
    end

    // Stage 2: 4-bit group addition pipeline
    reg [THERMO_WIDTH-1:0] sum_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= {THERMO_WIDTH{1'b0}};
        end else begin
            sum_stage2[0] <= sum_stage1[0];
            sum_stage2[1] <= sum_stage1[1];
            sum_stage2[2] <= sum_stage1[0] + sum_stage1[2];
            sum_stage2[3] <= sum_stage1[1] + sum_stage1[3];
            sum_stage2[4] <= sum_stage1[4];
            sum_stage2[5] <= sum_stage1[4] + sum_stage1[5];
            sum_stage2[6] <= sum_stage1[2] + sum_stage1[4] + sum_stage1[6];
        end
    end

    // Stage 3: Parallel Prefix Sum Register
    reg [3:0] parallel_prefix_sum;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parallel_prefix_sum <= 4'd0;
        else
            parallel_prefix_sum <= sum_stage2[0] + sum_stage2[1] + sum_stage2[2] + 
                                   sum_stage2[3] + sum_stage2[4] + sum_stage2[5] + sum_stage2[6];
    end

    // Stage 4: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_out <= {($clog2(THERMO_WIDTH+1)){1'b0}};
        else
            binary_out <= parallel_prefix_sum[$clog2(THERMO_WIDTH+1)-1:0];
    end

endmodule