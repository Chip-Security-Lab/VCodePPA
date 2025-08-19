//SystemVerilog
module ResetMultiplier(
    input clk, rst,
    input [3:0] x, y,
    output reg [7:0] out
);

    // Pipeline stage 1 registers
    reg [3:0] x_stage1, y_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] partial_prod_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] final_prod_stage3;
    reg valid_stage3;

    // Stage 1: Input sampling with optimized reset
    always @(posedge clk) begin
        if(rst) begin
            {x_stage1, y_stage1, valid_stage1} <= 0;
        end
        else begin
            x_stage1 <= x;
            y_stage1 <= y;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Partial product calculation with optimized multiplication
    always @(posedge clk) begin
        if(rst) begin
            {partial_prod_stage2, valid_stage2} <= 0;
        end
        else begin
            if(valid_stage1) begin
                partial_prod_stage2 <= {4'b0, x_stage1} * {4'b0, y_stage1};
                valid_stage2 <= 1'b1;
            end
            else begin
                valid_stage2 <= 1'b0;
            end
        end
    end

    // Stage 3: Final result with optimized reset
    always @(posedge clk) begin
        if(rst) begin
            {final_prod_stage3, valid_stage3} <= 0;
        end
        else begin
            if(valid_stage2) begin
                final_prod_stage3 <= partial_prod_stage2;
                valid_stage3 <= 1'b1;
            end
            else begin
                valid_stage3 <= 1'b0;
            end
        end
    end

    // Output assignment with optimized reset
    always @(posedge clk) begin
        if(rst) out <= 8'b0;
        else out <= final_prod_stage3;
    end

endmodule