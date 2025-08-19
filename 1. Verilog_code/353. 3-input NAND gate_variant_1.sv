//SystemVerilog
// Top-level module that implements a 3-input NAND gate with pipelined structure
module nand3_1 #(
    parameter PIPE_STAGES = 2,    // Number of pipeline stages
    parameter INPUT_REG   = 1,    // Enable input registers
    parameter OUTPUT_REG  = 1     // Enable output register
) (
    input  wire       clk,        // Clock input
    input  wire       rst_n,      // Active-low reset
    input  wire       A,          // Data input A
    input  wire       B,          // Data input B
    input  wire       C,          // Data input C
    output wire       Y           // NAND output
);

    // Input registration stage
    reg [2:0] inputs_r;
    wire [2:0] inputs_w;
    
    // Pipeline registers for AND operation
    reg and_stage1_r;
    wire and_stage1_w;
    
    // Final output register
    reg nand_out_r;
    
    // Input stage - register or pass-through based on parameter
    generate
        if (INPUT_REG) begin : INPUT_REGISTRATION
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    inputs_r <= 3'b000;
                else
                    inputs_r <= {A, B, C};
            end
            assign inputs_w = inputs_r;
        end else begin : INPUT_DIRECT
            assign inputs_w = {A, B, C};
        end
    endgenerate
    
    // First pipeline stage - AND operation
    generate
        if (PIPE_STAGES > 0) begin : STAGE1_PIPELINE
            // Pipelined AND logic
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    and_stage1_r <= 1'b0;
                else
                    and_stage1_r <= &inputs_w; // AND all inputs
            end
            assign and_stage1_w = and_stage1_r;
        end else begin : STAGE1_DIRECT
            // Direct AND logic
            assign and_stage1_w = &inputs_w;
        end
    endgenerate
    
    // Output stage - NAND operation with optional registration
    generate
        if (OUTPUT_REG) begin : OUTPUT_REGISTRATION
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    nand_out_r <= 1'b1;
                else
                    nand_out_r <= ~and_stage1_w;
            end
            assign Y = nand_out_r;
        end else begin : OUTPUT_DIRECT
            assign Y = ~and_stage1_w;
        end
    endgenerate

endmodule