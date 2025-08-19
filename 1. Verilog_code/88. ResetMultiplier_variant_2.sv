//SystemVerilog
module ResetMultiplier(
    input clk, rst,
    input [3:0] x, y,
    output reg [7:0] out
);

    // Pipeline registers
    reg [3:0] x_stage1, y_stage1;
    reg [7:0] partial_prod_stage2;
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Input register - x and y values
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            x_stage1 <= 0;
            y_stage1 <= 0;
        end else begin
            x_stage1 <= x;
            y_stage1 <= y;
        end
    end
    
    // Stage 1: Input register - valid signal
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2: Multiplication - partial product
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            partial_prod_stage2 <= 0;
        end else if(valid_stage1) begin
            partial_prod_stage2 <= x_stage1 * y_stage1;
        end
    end
    
    // Stage 2: Multiplication - valid signal
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output register
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            out <= 0;
        end else if(valid_stage2) begin
            out <= partial_prod_stage2;
        end
    end

endmodule