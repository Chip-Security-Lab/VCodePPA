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

    // Stage 1: Subtract and multiply
    reg  signed [WIDTH:0]        temp_diff_stage1;
    reg  signed [WIDTH+1:0]      mult_result_stage1;
    reg                          valid_stage1;
    reg  [WIDTH-1:0]             raw_data_stage1;

    // Stage 2: Add and final output
    reg  signed [WIDTH+2:0]      offset_stage2;
    reg  [WIDTH-1:0]             raw_data_stage2;
    reg                          valid_stage2;

    // Stage 1: temp_diff = temp_sensor - 2048; mult_result = temp_diff * 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_diff_stage1   <= 0;
            mult_result_stage1 <= 0;
            valid_stage1       <= 1'b0;
            raw_data_stage1    <= 0;
        end else begin
            temp_diff_stage1   <= $signed({1'b0, temp_sensor}) - 12'd2048;
            mult_result_stage1 <= temp_diff_stage1 * 3;
            valid_stage1       <= valid_in;
            raw_data_stage1    <= raw_data;
        end
    end

    // Stage 2: offset = mult_result; comp_data = raw_data + offset[WIDTH+2:3]
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            offset_stage2    <= 0;
            raw_data_stage2  <= 0;
            valid_stage2     <= 1'b0;
        end else begin
            offset_stage2    <= {{(WIDTH+3-(WIDTH+2)){mult_result_stage1[WIDTH+1]}}, mult_result_stage1};
            raw_data_stage2  <= raw_data_stage1;
            valid_stage2     <= valid_stage1;
        end
    end

    // Stage 3: Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_data  <= 0;
            valid_out  <= 1'b0;
        end else begin
            comp_data  <= raw_data_stage2 + offset_stage2[WIDTH+2:3];
            valid_out  <= valid_stage2;
        end
    end

endmodule