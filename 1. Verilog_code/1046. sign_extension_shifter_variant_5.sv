//SystemVerilog
module sign_extension_shifter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] input_data,
    input  wire [3:0]  shift_right,
    input  wire        sign_extend,
    output wire [15:0] result
);

    //--------------------------------------------------------------------------
    // Stage 1: Input Register Stage
    //--------------------------------------------------------------------------
    reg [15:0] input_data_stage1;
    reg [3:0]  shift_right_stage1;
    reg        sign_extend_stage1;
    reg        sign_bit_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_data_stage1    <= 16'd0;
            shift_right_stage1   <= 4'd0;
            sign_extend_stage1   <= 1'b0;
            sign_bit_stage1      <= 1'b0;
        end else begin
            input_data_stage1    <= input_data;
            shift_right_stage1   <= shift_right;
            sign_extend_stage1   <= sign_extend;
            sign_bit_stage1      <= input_data[15];
        end
    end

    //--------------------------------------------------------------------------
    // Stage 2: Logical and Arithmetic Shift Computation
    //--------------------------------------------------------------------------
    reg [15:0] logical_shift_stage2;
    reg [15:0] arithmetic_shift_stage2;

    // Logical Right Shift Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            logical_shift_stage2 <= 16'd0;
        end else begin
            case (shift_right_stage1)
                4'd0:  logical_shift_stage2 <= input_data_stage1;
                4'd1:  logical_shift_stage2 <= {1'b0,    input_data_stage1[15:1]};
                4'd2:  logical_shift_stage2 <= {2'b0,    input_data_stage1[15:2]};
                4'd3:  logical_shift_stage2 <= {3'b0,    input_data_stage1[15:3]};
                4'd4:  logical_shift_stage2 <= {4'b0,    input_data_stage1[15:4]};
                4'd5:  logical_shift_stage2 <= {5'b0,    input_data_stage1[15:5]};
                4'd6:  logical_shift_stage2 <= {6'b0,    input_data_stage1[15:6]};
                4'd7:  logical_shift_stage2 <= {7'b0,    input_data_stage1[15:7]};
                4'd8:  logical_shift_stage2 <= {8'b0,    input_data_stage1[15:8]};
                4'd9:  logical_shift_stage2 <= {9'b0,    input_data_stage1[15:9]};
                4'd10: logical_shift_stage2 <= {10'b0,   input_data_stage1[15:10]};
                4'd11: logical_shift_stage2 <= {11'b0,   input_data_stage1[15:11]};
                4'd12: logical_shift_stage2 <= {12'b0,   input_data_stage1[15:12]};
                4'd13: logical_shift_stage2 <= {13'b0,   input_data_stage1[15:13]};
                4'd14: logical_shift_stage2 <= {14'b0,   input_data_stage1[15:14]};
                4'd15: logical_shift_stage2 <= {15'b0,   input_data_stage1[15]};
                default: logical_shift_stage2 <= input_data_stage1;
            endcase
        end
    end

    // Arithmetic Right Shift Pipeline (Sign Extension)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arithmetic_shift_stage2 <= 16'd0;
        end else begin
            case (shift_right_stage1)
                4'd0:  arithmetic_shift_stage2 <= input_data_stage1;
                4'd1:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {1'b1,    input_data_stage1[15:1]}     : {1'b0,    input_data_stage1[15:1]};
                4'd2:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {2'b11,   input_data_stage1[15:2]}     : {2'b00,   input_data_stage1[15:2]};
                4'd3:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {3'b111,  input_data_stage1[15:3]}     : {3'b000,  input_data_stage1[15:3]};
                4'd4:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {4'b1111, input_data_stage1[15:4]}     : {4'b0000, input_data_stage1[15:4]};
                4'd5:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {5'b11111, input_data_stage1[15:5]}    : {5'b00000, input_data_stage1[15:5]};
                4'd6:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {6'b111111, input_data_stage1[15:6]}   : {6'b000000, input_data_stage1[15:6]};
                4'd7:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {7'b1111111, input_data_stage1[15:7]}  : {7'b0000000, input_data_stage1[15:7]};
                4'd8:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {8'b11111111, input_data_stage1[15:8]} : {8'b00000000, input_data_stage1[15:8]};
                4'd9:  arithmetic_shift_stage2 <= sign_bit_stage1 ? {9'b111111111, input_data_stage1[15:9]}: {9'b000000000, input_data_stage1[15:9]};
                4'd10: arithmetic_shift_stage2 <= sign_bit_stage1 ? {10'b1111111111, input_data_stage1[15:10]}  : {10'b0000000000, input_data_stage1[15:10]};
                4'd11: arithmetic_shift_stage2 <= sign_bit_stage1 ? {11'b11111111111, input_data_stage1[15:11]} : {11'b00000000000, input_data_stage1[15:11]};
                4'd12: arithmetic_shift_stage2 <= sign_bit_stage1 ? {12'b111111111111, input_data_stage1[15:12]}: {12'b000000000000, input_data_stage1[15:12]};
                4'd13: arithmetic_shift_stage2 <= sign_bit_stage1 ? {13'b1111111111111, input_data_stage1[15:13]} : {13'b0000000000000, input_data_stage1[15:13]};
                4'd14: arithmetic_shift_stage2 <= sign_bit_stage1 ? {14'b11111111111111, input_data_stage1[15:14]}: {14'b00000000000000, input_data_stage1[15:14]};
                4'd15: arithmetic_shift_stage2 <= sign_bit_stage1 ? {15'b111111111111111, input_data_stage1[15]}  : {15'b000000000000000, input_data_stage1[15]};
                default: arithmetic_shift_stage2 <= input_data_stage1;
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // Stage 3: Output Selection and Registering
    //--------------------------------------------------------------------------
    reg [15:0] result_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage3 <= 16'd0;
        end else begin
            result_stage3 <= sign_extend_stage1 ? arithmetic_shift_stage2 : logical_shift_stage2;
        end
    end

    //--------------------------------------------------------------------------
    // Output Assignment
    //--------------------------------------------------------------------------
    assign result = result_stage3;

endmodule