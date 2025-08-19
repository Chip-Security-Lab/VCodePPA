//SystemVerilog
module LZW_Encoder #(DICT_DEPTH=256) (
    input clk, en,
    input [7:0] data,
    output reg [15:0] code
);
    reg [7:0] dict [DICT_DEPTH-1:0];
    reg [15:0] current_code;
    
    // Registered input data
    reg [7:0] data_reg;
    
    // Pipeline stage signals
    reg match_found;
    reg [15:0] next_code;
    
    // Buffer registers for high fan-out current_code signal
    reg [15:0] current_code_dict; // For dictionary access
    reg [15:0] current_code_match; // For match comparison
    reg [15:0] current_code_next;  // For next_code calculation
    
    always @(posedge clk) begin
        if(en) begin
            // Distribute current_code to buffer registers
            current_code_dict <= current_code;
            current_code_match <= current_code;
            current_code_next <= current_code;
            
            // Register input
            data_reg <= data;
            
            // Determine match and next code in pipeline using buffered signals
            match_found <= (dict[current_code_dict] == data_reg);
            next_code <= current_code_next + 1;
            
            // Final stage logic
            if(match_found)
                current_code <= next_code;
            else begin
                code <= current_code;
                dict[current_code_dict] <= data_reg;
                current_code <= 0;
            end
        end
    end
    
    // Initialize current_code
    initial current_code = 0;
    initial current_code_dict = 0;
    initial current_code_match = 0;
    initial current_code_next = 0;
endmodule