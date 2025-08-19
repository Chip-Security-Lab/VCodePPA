//SystemVerilog
//IEEE 1364-2005 Verilog
// Top level module - nand_xor_xnor_gate with pipelined data path
module nand_xor_xnor_gate #(
    parameter PIPELINE_STAGES = 2
) (
    input wire clk,         // Clock signal
    input wire reset_n,     // Active low reset
    input wire A, B, C,     // Primary inputs
    output reg Y            // Registered output
);
    // Pipeline stage signals
    reg [PIPELINE_STAGES-1:0] A_pipe, B_pipe, C_pipe;
    wire nand_out, xnor_out;
    reg nand_reg, xnor_reg;
    wire xor_out;
    
    // A_pipe shift register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            A_pipe <= {PIPELINE_STAGES{1'b0}};
        end else begin
            A_pipe <= {A_pipe[PIPELINE_STAGES-2:0], A};
        end
    end
    
    // B_pipe shift register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            B_pipe <= {PIPELINE_STAGES{1'b0}};
        end else begin
            B_pipe <= {B_pipe[PIPELINE_STAGES-2:0], B};
        end
    end
    
    // C_pipe shift register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            C_pipe <= {PIPELINE_STAGES{1'b0}};
        end else begin
            C_pipe <= {C_pipe[PIPELINE_STAGES-2:0], C};
        end
    end
    
    // Stage 1: NAND and XNOR operations (parallel data paths)
    basic_nand_gate #(.DELAY(1)) nand_inst (
        .A(A_pipe[PIPELINE_STAGES-1]),
        .B(B_pipe[PIPELINE_STAGES-1]),
        .Y(nand_out)
    );
    
    basic_xnor_gate #(.DELAY(1)) xnor_inst (
        .A(C_pipe[PIPELINE_STAGES-1]),
        .B(A_pipe[PIPELINE_STAGES-1]),
        .Y(xnor_out)
    );
    
    // Register nand_out
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            nand_reg <= 1'b0;
        end else begin
            nand_reg <= nand_out;
        end
    end
    
    // Register xnor_out
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            xnor_reg <= 1'b0;
        end else begin
            xnor_reg <= xnor_out;
        end
    end
    
    // Stage 2: XOR operation (final stage)
    basic_xor_gate #(.DELAY(1)) xor_inst (
        .A(nand_reg),
        .B(xnor_reg),
        .Y(xor_out)
    );
    
    // Register the final output
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            Y <= 1'b0;
        end else begin
            Y <= xor_out;
        end
    end
    
endmodule

// Optimized basic NAND gate 
module basic_nand_gate #(
    parameter DELAY = 1
) (
    input wire A, B,
    output wire Y
);
    assign #DELAY Y = ~(A & B);
endmodule

// Optimized basic XNOR gate
module basic_xnor_gate #(
    parameter DELAY = 1
) (
    input wire A, B,
    output wire Y
);
    assign #DELAY Y = ~(A ^ B); // Optimized implementation
endmodule

// Optimized basic XOR gate
module basic_xor_gate #(
    parameter DELAY = 1
) (
    input wire A, B,
    output wire Y
);
    assign #DELAY Y = A ^ B;
endmodule