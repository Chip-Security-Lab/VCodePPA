//SystemVerilog
module Integrator #(parameter W=8, MAX=255) (
    input clk, rst,
    input [W-1:0] din,
    input valid_in,           // Input valid signal
    output reg valid_out,     // Output valid signal
    output reg [W-1:0] dout
);
    // Pipeline stage 1 - Input registration and accumulation
    reg [W-1:0] din_stage1;
    reg [W+1:0] accumulator;
    reg valid_stage1;
    
    // Pipeline stage 2 - Saturation calculation preparation
    reg [W+1:0] accumulator_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 - Output saturation calculation
    reg [W+1:0] accumulator_stage3;
    reg valid_stage3;
    
    // Stage 1: Input registration and accumulation
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            din_stage1 <= 0;
            accumulator <= 0;
            valid_stage1 <= 0;
        end
        else begin
            din_stage1 <= din;
            accumulator <= accumulator + din_stage1;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Buffer for accumulator signal
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            accumulator_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            accumulator_stage2 <= accumulator;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Prepare for saturation check
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            accumulator_stage3 <= 0;
            valid_stage3 <= 0;
        end
        else begin
            accumulator_stage3 <= accumulator_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Final output with saturation logic
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            dout <= 0;
            valid_out <= 0;
        end
        else begin
            dout <= (accumulator_stage3 > MAX) ? MAX : accumulator_stage3[W-1:0];
            valid_out <= valid_stage3;
        end
    end
endmodule