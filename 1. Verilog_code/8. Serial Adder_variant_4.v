module serial_adder_pipelined (
    input clk,
    input rst_n,
    input a,
    input b,
    input valid_in,
    output reg valid_out,
    output reg sum
);

    // Pipeline registers
    reg carry_stage1;
    reg a_stage1, b_stage1;
    reg valid_stage1;
    
    reg carry_stage2;
    reg sum_stage2;
    reg valid_stage2;

    // Stage 1: Input register and carry calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage1 <= 1'b0;
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            carry_stage1 <= carry_stage2;
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Sum calculation using optimized logic
    wire sum_temp = a_stage1 ^ b_stage1 ^ carry_stage1;
    wire carry_temp = (a_stage1 & b_stage1) | (a_stage1 & carry_stage1) | (b_stage1 & carry_stage1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage2 <= 1'b0;
            sum_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            carry_stage2 <= carry_temp;
            sum_stage2 <= sum_temp;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            sum <= sum_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule