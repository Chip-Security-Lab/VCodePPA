//SystemVerilog
module Interrupt_Hamming_Decoder(
    input clk,
    input [7:0] code_in,
    output reg [3:0] data_out,
    output reg uncorrectable_irq
);
    // Pipeline registers
    reg [7:0] code_stage1;
    reg parity_check;
    reg check0_result, check1_result;
    reg [3:0] data_stage1;
    reg [1:0] error_state_temp;
    
    // First pipeline stage - store inputs and compute parity
    always @(posedge clk) begin
        code_stage1 <= code_in;
        parity_check <= (^code_in != 0);
        data_stage1 <= code_in[7:4];
    end
    
    // Second pipeline stage - compute individual check bits
    always @(posedge clk) begin
        check0_result <= code_stage1[7] ^ code_stage1[6] ^ code_stage1[5] ^ code_stage1[4] ^ code_stage1[0];
        check1_result <= code_stage1[7] ^ code_stage1[6] ^ code_stage1[3] ^ code_stage1[2] ^ code_stage1[1];
    end
    
    // Third pipeline stage - determine error state
    always @(posedge clk) begin
        if (!parity_check) begin
            error_state_temp <= 2'b00; // No error
        end else begin
            if (check0_result)
                error_state_temp <= 2'b01; // 1-bit error
            else if (check1_result)
                error_state_temp <= 2'b10; // 1-bit error
            else
                error_state_temp <= 2'b11; // Uncorrectable error
        end
    end
    
    // Final stage - output registers
    always @(posedge clk) begin
        data_out <= data_stage1;
        uncorrectable_irq <= (error_state_temp == 2'b11);
    end
endmodule