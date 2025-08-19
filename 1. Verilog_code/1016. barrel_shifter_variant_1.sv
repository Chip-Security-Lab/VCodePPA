//SystemVerilog
// Top-level pipelined barrel shifter module with modular always blocks
module barrel_shifter #(parameter N = 8) (
    input                          clk,
    input                          rst_n,
    input        [N-1:0]           data_in,
    input        [$clog2(N)-1:0]   shift_amount,
    output reg   [N-1:0]           data_out
);

    // Stage 1 Registers
    reg [N-1:0] stage1_data_in;
    reg [$clog2(N)-1:0] stage1_shift_amount;

    // Stage 2 Registers
    reg [N-1:0] stage2_shift_left;
    reg [N-1:0] stage2_shift_right;
    reg [$clog2(N)-1:0] stage2_shift_amount;

    // Stage 3 Internal Signal
    reg [N-1:0] stage3_merged_shift;

    //==========================================================
    // Stage 1: Input Registering
    //==========================================================
    // Registers input data and shift amount on rising edge of clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data_in      <= {N{1'b0}};
            stage1_shift_amount <= {$clog2(N){1'b0}};
        end else begin
            stage1_data_in      <= data_in;
            stage1_shift_amount <= shift_amount;
        end
    end

    //==========================================================
    // Stage 2: Shift Left Calculation
    //==========================================================
    // Calculates left shift result based on registered input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_shift_left <= {N{1'b0}};
        end else begin
            stage2_shift_left <= stage1_data_in << (N - stage1_shift_amount);
        end
    end

    //==========================================================
    // Stage 2: Shift Right Calculation
    //==========================================================
    // Calculates right shift result based on registered input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_shift_right <= {N{1'b0}};
        end else begin
            stage2_shift_right <= stage1_data_in >> stage1_shift_amount;
        end
    end

    //==========================================================
    // Stage 2: Shift Amount Registering
    //==========================================================
    // Passes shift amount to next stage for timing consistency
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_shift_amount <= {$clog2(N){1'b0}};
        end else begin
            stage2_shift_amount <= stage1_shift_amount;
        end
    end

    //==========================================================
    // Stage 3: Merge Shift Results
    //==========================================================
    // Performs bitwise OR of left and right shift results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_merged_shift <= {N{1'b0}};
        end else begin
            stage3_merged_shift <= stage2_shift_left | stage2_shift_right;
        end
    end

    //==========================================================
    // Stage 3: Output Registering
    //==========================================================
    // Registers final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {N{1'b0}};
        end else begin
            data_out <= stage3_merged_shift;
        end
    end

endmodule