//SystemVerilog
module compare_shadow_reg_pipeline #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update_main,
    input wire update_shadow,
    output reg [WIDTH-1:0] main_data,
    output reg [WIDTH-1:0] shadow_data,
    output reg data_match
);

    // Pipeline registers
    reg [WIDTH-1:0] data_in_stage1;
    reg [WIDTH-1:0] main_data_stage1;
    reg [WIDTH-1:0] shadow_data_stage1;
    reg valid_stage1, valid_stage2;

    // Buffer for high fanout signal clk
    wire clk_buf;
    assign clk_buf = clk; // Buffering the clk signal

    // Stage 1: Input register
    always @(posedge clk_buf or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1 <= 1; // Indicate valid data in stage 1
        end
    end

    // Stage 2: Main register update
    always @(posedge clk_buf or negedge rst_n) begin
        if (!rst_n) begin
            main_data_stage1 <= 0;
        end else if (update_main) begin
            main_data_stage1 <= data_in_stage1;
        end
    end

    // Stage 3: Shadow register update
    always @(posedge clk_buf or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data_stage1 <= 0;
            valid_stage2 <= 0;
        end else if (update_shadow) begin
            shadow_data_stage1 <= data_in_stage1;
            valid_stage2 <= 1; // Indicate valid data in stage 2
        end
    end

    // Stage 4: Continuous comparison
    always @(posedge clk_buf or negedge rst_n) begin
        if (!rst_n) begin
            data_match <= 0;
        end else if (valid_stage1 && valid_stage2) begin
            data_match <= (main_data_stage1 == shadow_data_stage1) ? 1'b1 : 1'b0;
        end
    end

    // Output assignments
    always @(posedge clk_buf or negedge rst_n) begin
        if (!rst_n) begin
            main_data <= 0;
            shadow_data <= 0;
        end else begin
            main_data <= main_data_stage1;
            shadow_data <= shadow_data_stage1;
        end
    end

endmodule