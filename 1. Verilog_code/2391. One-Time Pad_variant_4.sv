//SystemVerilog
module one_time_pad #(parameter WIDTH = 24) (
    input wire clk, reset_n,
    input wire activate, new_key,
    input wire [WIDTH-1:0] data_input, key_input,
    output reg [WIDTH-1:0] data_output,
    output reg ready
);
    reg [WIDTH-1:0] current_key;
    reg [WIDTH-1:0] data_input_reg;
    reg [WIDTH-1:0] key_input_reg;
    reg activate_reg, new_key_reg;
    reg reset_n_reg;
    wire [WIDTH-1:0] xor_result;
    
    // Register inputs to improve timing
    always @(posedge clk) begin
        data_input_reg <= data_input;
        key_input_reg <= key_input;
        activate_reg <= activate;
        new_key_reg <= new_key;
        reset_n_reg <= reset_n;
    end
    
    // Pre-compute XOR result (moved before register)
    assign xor_result = data_input_reg ^ current_key;
    
    // Control signal combination
    wire [2:0] control;
    assign control = {!reset_n_reg, new_key_reg, activate_reg & ready};
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_key <= 0;
            data_output <= 0;
            ready <= 0;
        end else begin
            case (control)
                3'b100, 3'b101, 3'b110, 3'b111: begin  // Reset is active (registered)
                    current_key <= 0;
                    data_output <= 0;
                    ready <= 0;
                end
                3'b010, 3'b011: begin  // New key (higher priority than activate)
                    current_key <= key_input_reg;
                    ready <= 1;
                end
                3'b001: begin  // Activate and ready
                    data_output <= xor_result;  // Use pre-computed XOR result
                    ready <= 0;  // One-time use
                end
                default: begin  // No action (3'b000)
                    current_key <= current_key;
                    data_output <= data_output;
                    ready <= ready;
                end
            endcase
        end
    end
endmodule