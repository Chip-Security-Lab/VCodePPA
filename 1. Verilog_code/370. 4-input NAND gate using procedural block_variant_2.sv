//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: nand4_6
// Description: 4-input NAND gate with optimized pipelined structure
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module nand4_6 (
    input  wire clk,    // Clock input
    input  wire rst_n,  // Active low reset
    input  wire A,      // Input A
    input  wire B,      // Input B
    input  wire C,      // Input C
    input  wire D,      // Input D
    output reg  Y       // Output Y
);

    // Internal pipeline registers
    reg stage1_A, stage1_B;
    reg stage1_C, stage1_D;
    reg stage2_AB, stage2_CD;
    
    // First pipeline stage - register input A
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
        end else begin
            stage1_A <= A;
        end
    end
    
    // First pipeline stage - register input B
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_B <= 1'b0;
        end else begin
            stage1_B <= B;
        end
    end
    
    // First pipeline stage - register input C
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_C <= 1'b0;
        end else begin
            stage1_C <= C;
        end
    end
    
    // First pipeline stage - register input D
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_D <= 1'b0;
        end else begin
            stage1_D <= D;
        end
    end
    
    // Second pipeline stage - A AND B operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_AB <= 1'b0;
        end else begin
            stage2_AB <= stage1_A & stage1_B;
        end
    end
    
    // Second pipeline stage - C AND D operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_CD <= 1'b0;
        end else begin
            stage2_CD <= stage1_C & stage1_D;
        end
    end
    
    // Final pipeline stage - complete NAND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b1;  // NAND output is high when reset
        end else begin
            Y <= ~(stage2_AB & stage2_CD);
        end
    end

endmodule