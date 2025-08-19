//SystemVerilog
module clk_gate_mask #(parameter MASK=4'b1100) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       valid_in,
    output wire       valid_out,
    output reg  [3:0] out
);

    // Optimized pipeline structure with reduced registers
    reg        en_q;
    reg        valid_q;
    reg [3:0]  masked_data;
    
    // First pipeline stage - capture enable and valid signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_q    <= 1'b0;
            valid_q <= 1'b0;
        end else begin
            en_q    <= en;
            valid_q <= valid_in;
        end
    end
    
    // Pre-compute masked data to reduce critical path
    always @(*) begin
        masked_data = en_q ? (out | MASK) : out;
    end
    
    // Output stage - apply mask based on enable condition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 4'b0000;
        end else if (valid_q) begin
            out <= masked_data;
        end
    end
    
    // Valid output pipeline
    reg valid_out_q;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out_q <= 1'b0;
        end else begin
            valid_out_q <= valid_q;
        end
    end
    
    assign valid_out = valid_out_q;
    
endmodule