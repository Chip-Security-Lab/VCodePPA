//SystemVerilog
module group_shifter(
    input               clk,
    input               reset,
    input        [31:0] data_in,
    input        [1:0]  group_count,  // Number of 4-bit groups to shift
    input               dir,          // 1:left, 0:right
    output reg   [31:0] data_out,
    output reg          data_out_valid
);

    // Pipeline control signals
    reg                 valid_stage1, valid_stage2;
    reg                 dir_stage1,   dir_stage2;
    reg          [4:0]  bit_shift_stage1, bit_shift_stage2;
    reg         [31:0]  data_in_stage1, data_in_stage2;

    // Stage 1: Capture inputs and compute shift amount
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in_stage1    <= 32'b0;
            bit_shift_stage1  <= 5'b0;
            dir_stage1        <= 1'b0;
            valid_stage1      <= 1'b0;
        end else begin
            data_in_stage1    <= data_in;
            bit_shift_stage1  <= {group_count, 2'b00}; // Multiply by 4
            dir_stage1        <= dir;
            valid_stage1      <= 1'b1;
        end
    end

    // Stage 2: Pipeline shift parameters
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in_stage2    <= 32'b0;
            bit_shift_stage2  <= 5'b0;
            dir_stage2        <= 1'b0;
            valid_stage2      <= 1'b0;
        end else begin
            data_in_stage2    <= data_in_stage1;
            bit_shift_stage2  <= bit_shift_stage1;
            dir_stage2        <= dir_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Barrel shifter implementation for stage 3
    reg [31:0] barrel_shift_left;
    reg [31:0] barrel_shift_right;

    always @(*) begin
        // Left barrel shifter
        case (bit_shift_stage2[4])
            1'b0: barrel_shift_left = data_in_stage2;
            1'b1: barrel_shift_left = {data_in_stage2[15:0], 16'b0};
        endcase
        case (bit_shift_stage2[3])
            1'b0: barrel_shift_left = barrel_shift_left;
            1'b1: barrel_shift_left = {barrel_shift_left[23:0], 8'b0};
        endcase
        case (bit_shift_stage2[2])
            1'b0: barrel_shift_left = barrel_shift_left;
            1'b1: barrel_shift_left = {barrel_shift_left[27:0], 4'b0};
        endcase
        case (bit_shift_stage2[1])
            1'b0: barrel_shift_left = barrel_shift_left;
            1'b1: barrel_shift_left = {barrel_shift_left[29:0], 2'b0};
        endcase
        case (bit_shift_stage2[0])
            1'b0: barrel_shift_left = barrel_shift_left;
            1'b1: barrel_shift_left = {barrel_shift_left[30:0], 1'b0};
        endcase
    end

    always @(*) begin
        // Right barrel shifter
        case (bit_shift_stage2[4])
            1'b0: barrel_shift_right = data_in_stage2;
            1'b1: barrel_shift_right = {16'b0, data_in_stage2[31:16]};
        endcase
        case (bit_shift_stage2[3])
            1'b0: barrel_shift_right = barrel_shift_right;
            1'b1: barrel_shift_right = {8'b0, barrel_shift_right[31:8]};
        endcase
        case (bit_shift_stage2[2])
            1'b0: barrel_shift_right = barrel_shift_right;
            1'b1: barrel_shift_right = {4'b0, barrel_shift_right[31:4]};
        endcase
        case (bit_shift_stage2[1])
            1'b0: barrel_shift_right = barrel_shift_right;
            1'b1: barrel_shift_right = {2'b0, barrel_shift_right[31:2]};
        endcase
        case (bit_shift_stage2[0])
            1'b0: barrel_shift_right = barrel_shift_right;
            1'b1: barrel_shift_right = {1'b0, barrel_shift_right[31:1]};
        endcase
    end

    // Stage 3: Output register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out        <= 32'b0;
            data_out_valid  <= 1'b0;
        end else begin
            if (valid_stage2) begin
                data_out       <= dir_stage2 ? barrel_shift_left : barrel_shift_right;
                data_out_valid <= 1'b1;
            end else begin
                data_out_valid <= 1'b0;
            end
        end
    end

endmodule