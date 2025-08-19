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

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end

    // Stage 1: Carry and valid registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            carry_stage1 <= carry_stage2;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Addition computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_stage2 <= 1'b0;
            sum_stage2 <= 1'b0;
        end else begin
            {carry_stage2, sum_stage2} <= a_stage1 + b_stage1 + carry_stage1;
        end
    end

    // Stage 2: Valid propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // Output: Sum registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 1'b0;
        end else begin
            sum <= sum_stage2;
        end
    end

    // Output: Valid registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
        end
    end

endmodule