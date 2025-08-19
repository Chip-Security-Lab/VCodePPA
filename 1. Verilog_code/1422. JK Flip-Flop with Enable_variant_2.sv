//SystemVerilog
module jk_ff_enable (
    input wire clock_in,
    input wire enable_sig,
    input wire j_input,
    input wire k_input,
    output reg q_output,
    // Pipeline control signals
    input wire reset_n,       // Active low reset
    input wire data_valid_in, // Input data valid signal
    output reg data_valid_out // Output data valid signal
);
    // Pipeline registers - stage 1
    reg j_stage1, k_stage1, enable_stage1, valid_stage1;
    reg q_stage1; // Current state in stage 1
    
    // Pipeline registers - stage 2
    reg [1:0] jk_combined_stage2;
    reg enable_stage2, valid_stage2;
    reg q_stage2; // Current state in stage 2
    
    // Pipeline stage 1: Input registration and preprocessing
    always @(posedge clock_in or negedge reset_n) begin
        if (!reset_n) begin
            j_stage1 <= 1'b0;
            k_stage1 <= 1'b0;
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            q_stage1 <= 1'b0;
        end else begin
            j_stage1 <= j_input;
            k_stage1 <= k_input;
            enable_stage1 <= enable_sig;
            valid_stage1 <= data_valid_in;
            q_stage1 <= q_output; // Capture current state
        end
    end
    
    // Pipeline stage 2: JK state calculation
    always @(posedge clock_in or negedge reset_n) begin
        if (!reset_n) begin
            jk_combined_stage2 <= 2'b00;
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            q_stage2 <= 1'b0;
        end else begin
            jk_combined_stage2 <= {j_stage1, k_stage1};
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
            q_stage2 <= q_stage1;
        end
    end
    
    // Pipeline stage 3: Output determination and state update
    // Flattened if-else structure using logical AND (&&)
    always @(posedge clock_in or negedge reset_n) begin
        if (!reset_n) begin
            q_output <= 1'b0;
            data_valid_out <= 1'b0;
        end else begin
            data_valid_out <= valid_stage2;
            
            if (valid_stage2 && enable_stage2 && jk_combined_stage2 == 2'b00)
                q_output <= q_stage2;     // Hold state
            else if (valid_stage2 && enable_stage2 && jk_combined_stage2 == 2'b01)
                q_output <= 1'b0;         // Reset
            else if (valid_stage2 && enable_stage2 && jk_combined_stage2 == 2'b10)
                q_output <= 1'b1;         // Set
            else if (valid_stage2 && enable_stage2 && jk_combined_stage2 == 2'b11)
                q_output <= ~q_stage2;    // Toggle
        end
    end
endmodule