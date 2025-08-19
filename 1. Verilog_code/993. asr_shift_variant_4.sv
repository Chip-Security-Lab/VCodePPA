//SystemVerilog
module asr_shift #(
    parameter DATA_W = 32
)(
    input wire clk_i,
    input wire rst_i,
    input wire [DATA_W-1:0] data_i,
    input wire [$clog2(DATA_W)-1:0] shift_i,
    input wire valid_i,
    output reg [DATA_W-1:0] data_o,
    output reg valid_o
);

    // Stage 1: Register input data and shift amount
    reg [DATA_W-1:0] data_stage1;
    reg [$clog2(DATA_W)-1:0] shift_stage1;
    reg valid_stage1;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            data_stage1 <= {DATA_W{1'b0}};
            shift_stage1 <= {$clog2(DATA_W){1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_i;
            shift_stage1 <= shift_i;
            valid_stage1 <= valid_i;
        end
    end

    // Stage 2: Prepare sign bit and right-shifted value
    reg sign_stage2;
    reg [DATA_W-1:0] right_shift_stage2;
    reg [$clog2(DATA_W)-1:0] shift_stage2;
    reg valid_stage2;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sign_stage2 <= 1'b0;
            right_shift_stage2 <= {DATA_W{1'b0}};
            shift_stage2 <= {$clog2(DATA_W){1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            sign_stage2 <= data_stage1[DATA_W-1];
            right_shift_stage2 <= data_stage1 >> shift_stage1;
            shift_stage2 <= shift_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output result with sign extension if needed
    reg [DATA_W-1:0] data_stage3;
    reg valid_stage3;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            data_stage3 <= {DATA_W{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            if (sign_stage2) begin
                // Arithmetic shift right with sign extension
                data_stage3 <= right_shift_stage2 | (~({DATA_W{1'b0}} >> shift_stage2));
            end else begin
                // Logical shift right
                data_stage3 <= right_shift_stage2;
            end
            valid_stage3 <= valid_stage2;
        end
    end

    // Output assignment
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            data_o <= {DATA_W{1'b0}};
            valid_o <= 1'b0;
        end else begin
            data_o <= data_stage3;
            valid_o <= valid_stage3;
        end
    end

endmodule