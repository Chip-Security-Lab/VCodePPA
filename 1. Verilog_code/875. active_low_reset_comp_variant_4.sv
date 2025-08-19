//SystemVerilog
module active_low_reset_comp #(parameter WIDTH = 4)(
    input clock, reset_n, enable,
    input [WIDTH-1:0][WIDTH-1:0] values, // Multiple values to compare
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg valid_result
);

    // Stage 1: Input Latching and Initialization
    reg [WIDTH-1:0][WIDTH-1:0] values_stage1;
    reg enable_stage1;
    reg [WIDTH-1:0] temp_val_stage1;
    reg [$clog2(WIDTH)-1:0] highest_idx_stage1;
    reg valid_stage1;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            values_stage1 <= 'b0;
            enable_stage1 <= 0;
            temp_val_stage1 <= 'b0;
            highest_idx_stage1 <= 'b0;
            valid_stage1 <= 0;
        end else begin
            values_stage1 <= values;
            enable_stage1 <= enable;
            temp_val_stage1 <= values[0];
            highest_idx_stage1 <= 0;
            valid_stage1 <= enable; // Valid in stage 1 if enable is high
        end
    end

    // Stage 2: Comparison Loop (Iterative Comparison)
    reg [WIDTH-1:0] temp_val_stage2;
    reg [$clog2(WIDTH)-1:0] highest_idx_stage2;
    reg valid_stage2;
    reg [WIDTH-1:0][WIDTH-1:0] values_stage2;

    integer j_stage2;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            temp_val_stage2 <= 'b0;
            highest_idx_stage2 <= 'b0;
            valid_stage2 <= 0;
            values_stage2 <= 'b0;
        end else begin
            temp_val_stage2 <= temp_val_stage1;
            highest_idx_stage2 <= highest_idx_stage1;
            valid_stage2 <= valid_stage1;
            values_stage2 <= values_stage1;

            if (valid_stage1) begin // Only perform comparison if valid in stage 1
                for (j_stage2 = 1; j_stage2 < WIDTH; j_stage2 = j_stage2 + 1) begin
                    if (values_stage1[j_stage2] > temp_val_stage1) begin
                        temp_val_stage2 <= values_stage1[j_stage2];
                        highest_idx_stage2 <= j_stage2[$clog2(WIDTH)-1:0];
                    end
                end
            end
        end
    end

    // Stage 3: Output Latching
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            highest_idx <= 'b0;
            valid_result <= 0;
        end else begin
            highest_idx <= highest_idx_stage2;
            valid_result <= valid_stage2;
        end
    end

endmodule