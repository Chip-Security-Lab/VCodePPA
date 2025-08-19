//SystemVerilog
//IEEE 1364-2005 Verilog
module Cascaded_AND (
    input  wire       clk,      // Clock input
    input  wire       rst_n,    // Active low reset
    input  wire [2:0] in,       // Input vector
    output reg        out       // Pipelined output
);
    // Pipeline registers for improved timing
    reg [2:0] in_pipe1;
    reg       stage1_result_pipe;
    
    // First pipeline stage: register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_pipe1 <= 3'b000;
        end
        else begin
            in_pipe1 <= in;
        end
    end
    
    // Second pipeline stage: compute first AND and register result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_result_pipe <= 1'b0;
        end
        else begin
            stage1_result_pipe <= in_pipe1[0] & in_pipe1[1];
        end
    end
    
    // Third pipeline stage: compute final AND and register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 1'b0;
        end
        else begin
            out <= stage1_result_pipe & in_pipe1[2];
        end
    end
    
endmodule