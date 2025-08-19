module FSM_Sub_Pipelined(
    input clk,
    input rst_n,
    input start,
    input [7:0] A,
    input [7:0] B,
    output reg done,
    output reg [7:0] res
);

    // Pipeline stage registers
    reg [7:0] A_stage1, B_stage1;
    reg valid_stage1;
    reg [7:0] result_stage2;
    reg valid_stage2;
    
    // Stage 1: Input register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_stage1 <= 8'b0;
            B_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end
        else if (start) begin
            A_stage1 <= A;
            B_stage1 <= B;
            valid_stage1 <= 1'b1;
        end
        else begin
            A_stage1 <= A_stage1;
            B_stage1 <= B_stage1;
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Computation stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            result_stage2 <= A_stage1 - B_stage1;
            valid_stage2 <= 1'b1;
        end
        else begin
            result_stage2 <= result_stage2;
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 8'b0;
            done <= 1'b0;
        end
        else if (valid_stage2) begin
            res <= result_stage2;
            done <= 1'b1;
        end
        else begin
            res <= res;
            done <= 1'b0;
        end
    end

endmodule