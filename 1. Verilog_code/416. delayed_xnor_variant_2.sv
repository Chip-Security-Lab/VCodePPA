//SystemVerilog
module delayed_xnor (
    input  wire clk,    // Clock input
    input  wire rst_n,  // Reset signal
    input  wire a,      // First input operand
    input  wire b,      // Second input operand
    output reg  y       // XNOR result output
);

    // Compute combinational logic first, then register
    wire xnor_result_wire;
    reg xnor_stage1, xnor_stage2;
    
    // Combinational XNOR operation
    assign xnor_result_wire = ~(a ^ b);
    
    // First pipeline stage - register XNOR result directly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_stage1 <= 1'b0;
        end else begin
            xnor_stage1 <= xnor_result_wire;
        end
    end
    
    // Second pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_stage2 <= 1'b0;
        end else begin
            xnor_stage2 <= xnor_stage1;
        end
    end
    
    // Final pipeline stage - output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= xnor_stage2;
        end
    end

endmodule