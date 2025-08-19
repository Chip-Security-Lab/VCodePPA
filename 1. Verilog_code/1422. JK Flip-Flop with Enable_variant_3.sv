//SystemVerilog
module jk_ff_enable (
    input wire clock_in,
    input wire enable_sig,
    input wire j_input,
    input wire k_input,
    output reg q_output
);
    // Direct combinational signals
    wire [1:0] jk_combined = {j_input, k_input};
    
    // Pipeline valid signal
    reg valid_stage1;
    
    // Intermediate state for q_output
    reg q_intermediate;
    
    // First stage: Track validity only
    always @(posedge clock_in) begin
        valid_stage1 <= 1'b1; // Always valid after first clock
    end
    
    // Calculate next state combinationally
    always @(*) begin
        case (jk_combined)
            2'b00: q_intermediate = q_output;
            2'b01: q_intermediate = 1'b0;
            2'b10: q_intermediate = 1'b1;
            2'b11: q_intermediate = ~q_output;
            default: q_intermediate = q_output;
        endcase
    end
    
    // Second stage: Register the output after computation
    always @(posedge clock_in) begin
        if (valid_stage1 && enable_sig) begin
            q_output <= q_intermediate;
        end
    end
endmodule