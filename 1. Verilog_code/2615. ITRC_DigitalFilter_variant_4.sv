//SystemVerilog
module ITRC_DigitalFilter #(
    parameter WIDTH = 8,
    parameter FILTER_CYCLES = 3
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] noisy_int,
    output reg [WIDTH-1:0] filtered_int
);

    // Pipeline stage registers
    reg [WIDTH-1:0] shift_reg [0:FILTER_CYCLES-1];
    reg [WIDTH-1:0] sum_stage1_reg;
    reg [WIDTH-1:0] carry_stage1_reg;
    reg [WIDTH-1:0] sum_stage2_reg;
    reg [WIDTH-1:0] carry_stage2_reg;
    reg [WIDTH-1:0] sum_final_reg;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline stage 1: Shift register and initial sum/carry generation
    always @(posedge clk) begin
        if (!rst_n) begin
            for (integer i=0; i<FILTER_CYCLES; i=i+1)
                shift_reg[i] <= 0;
            valid_stage1 <= 0;
        end else begin
            shift_reg[0] <= noisy_int;
            for (integer i=1; i<FILTER_CYCLES; i=i+1)
                shift_reg[i] <= shift_reg[i-1];
            valid_stage1 <= 1;
        end
    end
    
    // Pipeline stage 2: First stage of Han-Carlson adder
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stage1_reg <= 0;
            carry_stage1_reg <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            for (integer j=0; j<WIDTH; j=j+1) begin
                sum_stage1_reg[j] <= shift_reg[0][j] ^ shift_reg[1][j];
                carry_stage1_reg[j] <= shift_reg[0][j] & shift_reg[1][j];
            end
            valid_stage2 <= 1;
        end else begin
            valid_stage2 <= 0;
        end
    end
    
    // Pipeline stage 3: Second stage of Han-Carlson adder
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stage2_reg <= 0;
            carry_stage2_reg <= 0;
            valid_stage3 <= 0;
        end else if (valid_stage2) begin
            sum_stage2_reg[0] <= sum_stage1_reg[0];
            carry_stage2_reg[0] <= carry_stage1_reg[0];
            
            for (integer j=1; j<WIDTH; j=j+1) begin
                sum_stage2_reg[j] <= sum_stage1_reg[j] ^ carry_stage1_reg[j-1];
                carry_stage2_reg[j] <= carry_stage1_reg[j] | (sum_stage1_reg[j] & carry_stage1_reg[j-1]);
            end
            valid_stage3 <= 1;
        end else begin
            valid_stage3 <= 0;
        end
    end
    
    // Pipeline stage 4: Final sum calculation
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_final_reg <= 0;
            filtered_int <= 0;
        end else if (valid_stage3) begin
            sum_final_reg[0] <= sum_stage2_reg[0];
            
            for (integer j=1; j<WIDTH; j=j+1) begin
                sum_final_reg[j] <= sum_stage2_reg[j] ^ carry_stage2_reg[j-1];
            end
            
            filtered_int <= sum_final_reg;
        end
    end

endmodule