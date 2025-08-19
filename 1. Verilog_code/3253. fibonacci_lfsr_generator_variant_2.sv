//SystemVerilog
module fibonacci_lfsr_generator (
    input  wire        clk_i,
    input  wire        arst_n_i,
    output wire [31:0] random_o,
    output wire        valid_o
);

    // Stage 1: Feedback calculation
    reg  [31:0] shift_register_stage1;
    reg         valid_stage1;
    wire        feedback_stage1;

    assign feedback_stage1 = ^(shift_register_stage1 & 32'h80200003);

    // Stage 2: Shift operation and pipeline register
    reg  [31:0] shift_register_stage2;
    reg         valid_stage2;

    // Pipeline control logic
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i) begin
            shift_register_stage1 <= 32'h1;
            valid_stage1          <= 1'b0;
        end else begin
            // Maintain previous value for continuous operation
            shift_register_stage1 <= shift_register_stage2;
            valid_stage1          <= valid_stage2;
        end
    end

    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i) begin
            shift_register_stage2 <= 32'h1;
            valid_stage2          <= 1'b1;
        end else begin
            shift_register_stage2 <= {shift_register_stage1[30:0], feedback_stage1};
            valid_stage2          <= valid_stage1;
        end
    end

    assign random_o = shift_register_stage2;
    assign valid_o  = valid_stage2;

endmodule