//SystemVerilog
module rect_to_polar #(
    parameter WIDTH = 16,
    parameter ITERATIONS = 8
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      valid_in,
    input  wire signed [WIDTH-1:0]   x_in,
    input  wire signed [WIDTH-1:0]   y_in,
    output wire                      valid_out,
    output wire [WIDTH-1:0]          magnitude,
    output wire [WIDTH-1:0]          angle
);

    // Pipeline stage signals
    localparam PIPELINE_DEPTH = ITERATIONS + 2; // 2 extra for input and output register stages

    // Pipeline registers for x, y, z, and valid
    reg signed [WIDTH-1:0] x_stage   [0:PIPELINE_DEPTH-2]; // Remove output reg, move to input of output logic
    reg signed [WIDTH-1:0] y_stage   [0:PIPELINE_DEPTH-2];
    reg        [WIDTH-1:0] z_stage   [0:PIPELINE_DEPTH-2];
    reg                   valid_stage[0:PIPELINE_DEPTH-2];

    // Output registers, moved before output combinational logic
    reg signed [WIDTH-1:0] x_out_reg;
    reg        [WIDTH-1:0] z_out_reg;
    reg                    valid_out_reg;

    // CORDIC atan table ROM
    reg signed [WIDTH-1:0] atan_table [0:ITERATIONS-1];

    integer i;

    // Initialize atan lookup table
    initial begin
        atan_table[0] = 32'd2949120;   // atan(2^-0) * 2^16
        atan_table[1] = 32'd1740992;   // atan(2^-1) * 2^16
        atan_table[2] = 32'd919872;    // atan(2^-2) * 2^16
        atan_table[3] = 32'd466944;    // atan(2^-3) * 2^16
        atan_table[4] = 32'd234368;    // atan(2^-4) * 2^16
        atan_table[5] = 32'd117312;    // atan(2^-5) * 2^16
        atan_table[6] = 32'd58688;     // atan(2^-6) * 2^16
        atan_table[7] = 32'd29312;     // atan(2^-7) * 2^16
    end

    // Pipeline input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_stage[0]     <= 0;
            y_stage[0]     <= 0;
            z_stage[0]     <= 0;
            valid_stage[0] <= 1'b0;
        end else begin
            x_stage[0]     <= x_in;
            y_stage[0]     <= y_in;
            z_stage[0]     <= 0;
            valid_stage[0] <= valid_in;
        end
    end

    // Main CORDIC pipeline stages
    genvar stage_idx;
    generate
        for (stage_idx = 0; stage_idx < ITERATIONS; stage_idx = stage_idx + 1) begin : cordic_pipeline
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    x_stage[stage_idx+1]     <= 0;
                    y_stage[stage_idx+1]     <= 0;
                    z_stage[stage_idx+1]     <= 0;
                    valid_stage[stage_idx+1] <= 1'b0;
                end else if (valid_stage[stage_idx]) begin
                    if (y_stage[stage_idx] >= 0) begin
                        x_stage[stage_idx+1]     <= x_stage[stage_idx] + (y_stage[stage_idx] >>> stage_idx);
                        y_stage[stage_idx+1]     <= y_stage[stage_idx] - (x_stage[stage_idx] >>> stage_idx);
                        z_stage[stage_idx+1]     <= z_stage[stage_idx] + atan_table[stage_idx];
                    end else begin
                        x_stage[stage_idx+1]     <= x_stage[stage_idx] - (y_stage[stage_idx] >>> stage_idx);
                        y_stage[stage_idx+1]     <= y_stage[stage_idx] + (x_stage[stage_idx] >>> stage_idx);
                        z_stage[stage_idx+1]     <= z_stage[stage_idx] - atan_table[stage_idx];
                    end
                    valid_stage[stage_idx+1]     <= valid_stage[stage_idx];
                end else begin
                    x_stage[stage_idx+1]     <= 0;
                    y_stage[stage_idx+1]     <= 0;
                    z_stage[stage_idx+1]     <= 0;
                    valid_stage[stage_idx+1] <= 1'b0;
                end
            end
        end
    endgenerate

    // Output register stage moved before output combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_out_reg      <= 0;
            z_out_reg      <= 0;
            valid_out_reg  <= 1'b0;
        end else begin
            x_out_reg      <= x_stage[PIPELINE_DEPTH-2];
            z_out_reg      <= z_stage[PIPELINE_DEPTH-2];
            valid_out_reg  <= valid_stage[PIPELINE_DEPTH-2];
        end
    end

    // Output assignments
    assign magnitude = x_out_reg[WIDTH-1:0];
    assign angle     = z_out_reg[WIDTH-1:0];
    assign valid_out = valid_out_reg;

endmodule