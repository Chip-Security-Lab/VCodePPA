//SystemVerilog
module Integrator #(parameter W=8, MAX=255) (
    input clk, rst,
    input [W-1:0] din,
    input valid_in,
    output reg valid_out,
    output reg [W-1:0] dout
);
    // Stage 1: Accumulation
    reg [W+1:0] accumulator;
    reg [W+1:0] stage1_result;
    reg valid_stage1;
    
    // Stage 2: Saturation
    reg [W-1:0] stage2_result;
    reg valid_stage2;
    
    // Stage 1: Accumulation stage
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            accumulator <= 0;
            valid_stage1 <= 0;
        end
        else begin
            if (valid_in) begin
                accumulator <= accumulator + din;
                valid_stage1 <= 1'b1;
            end
            else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 1 result calculation (moved after accumulator)
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            stage1_result <= 0;
        end
        else begin
            if (valid_in) begin
                stage1_result <= accumulator + din;
            end
        end
    end
    
    // Stage 2: Saturation stage
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            stage2_result <= 0;
            valid_stage2 <= 0;
        end
        else begin
            if (valid_stage1) begin
                stage2_result <= (stage1_result > MAX) ? MAX : stage1_result[W-1:0];
                valid_stage2 <= valid_stage1;
            end
            else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            dout <= 0;
            valid_out <= 0;
        end
        else begin
            dout <= stage2_result;
            valid_out <= valid_stage2;
        end
    end
endmodule