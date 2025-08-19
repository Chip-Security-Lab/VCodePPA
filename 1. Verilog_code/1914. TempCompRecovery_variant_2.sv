//SystemVerilog
module TempCompRecovery #(parameter WIDTH=12) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  valid_in,
    input  wire [WIDTH-1:0]      temp_sensor,
    input  wire [WIDTH-1:0]      raw_data,
    output reg                   valid_out,
    output reg  [WIDTH-1:0]      comp_data
);

    // Pipeline registers
    reg signed [WIDTH:0]         temp_diff_stage1;
    reg                          valid_stage1;
    reg [WIDTH-1:0]              raw_data_stage1;

    reg signed [WIDTH+1:0]       offset_stage2;
    reg                          valid_stage2;
    reg [WIDTH-1:0]              raw_data_stage2;

    reg [WIDTH-1:0]              comp_data_stage3;
    reg                          valid_stage3;

    // Combined always block for all pipeline stages and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_diff_stage1   <= { (WIDTH+1){1'b0} };
            valid_stage1       <= 1'b0;
            raw_data_stage1    <= { WIDTH{1'b0} };

            offset_stage2      <= { (WIDTH+2){1'b0} };
            valid_stage2       <= 1'b0;
            raw_data_stage2    <= { WIDTH{1'b0} };

            comp_data_stage3   <= { WIDTH{1'b0} };
            valid_stage3       <= 1'b0;

            comp_data         <= { WIDTH{1'b0} };
            valid_out         <= 1'b0;
        end else begin
            // Stage 1
            temp_diff_stage1   <= $signed({1'b0, temp_sensor}) - 12'd2048;
            valid_stage1       <= valid_in;
            raw_data_stage1    <= raw_data;

            // Stage 2
            offset_stage2      <= temp_diff_stage1 * 3;
            valid_stage2       <= valid_stage1;
            raw_data_stage2    <= raw_data_stage1;

            // Stage 3
            comp_data_stage3   <= raw_data_stage2 + offset_stage2[WIDTH+1:2];
            valid_stage3       <= valid_stage2;

            // Output
            comp_data         <= comp_data_stage3;
            valid_out         <= valid_stage3;
        end
    end

endmodule