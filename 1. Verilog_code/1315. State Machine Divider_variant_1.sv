//SystemVerilog
module fsm_divider (
    input wire clk_input,
    input wire reset,
    output wire clk_output
);
    // State encoding with one-hot to improve timing
    localparam [3:0] S0 = 4'b0001, 
                     S1 = 4'b0010, 
                     S2 = 4'b0100, 
                     S3 = 4'b1000;
    
    // State registers - use one-hot encoding for better PPA
    reg [3:0] current_state;
    reg [3:0] next_state;
    
    // Output pipeline register to improve timing
    reg clk_output_reg;
    
    // Sequential logic - state update
    always @(posedge clk_input or posedge reset) begin
        if (reset)
            current_state <= S0;
        else
            current_state <= next_state;
    end
    
    // Combinational logic - next state determination
    // Simple ring counter structure for clean data flow
    always @(*) begin
        case (current_state)
            S0: next_state = S1;
            S1: next_state = S2;
            S2: next_state = S3;
            S3: next_state = S0;
            default: next_state = S0;
        endcase
    end
    
    // Output logic pipeline
    always @(posedge clk_input or posedge reset) begin
        if (reset)
            clk_output_reg <= 1'b1;
        else
            clk_output_reg <= (next_state == S0 || next_state == S1);
    end
    
    // Final output assignment
    assign clk_output = clk_output_reg;
    
endmodule