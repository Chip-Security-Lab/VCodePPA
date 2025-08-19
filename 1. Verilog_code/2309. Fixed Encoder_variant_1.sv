//SystemVerilog
module fixed_encoder (
    input        clk,        // Added clock input for sequential multiplier
    input        rst_n,      // Added reset input for sequential multiplier
    input  [7:0] symbol,
    input        valid_in,
    output reg [3:0] code,
    output reg       valid_out,
    output reg [15:0] mult_result, // Output for multiplication result
    output reg       mult_valid    // Valid signal for multiplication result
);
    // Internal signals for encoding
    reg [3:0] encoded_value;
    
    // Internal signals for shift-and-add multiplier
    reg [3:0] multiplier;     // Store lower 4 bits for multiplication
    reg [3:0] multiplicand;   // Store upper 4 bits for multiplication
    reg [15:0] product;       // Store the product
    reg [2:0] mult_count;     // Counter for multiplication steps
    reg mult_in_progress;     // Flag to indicate multiplication in progress
    
    // State machine states for multiplier
    localparam IDLE = 2'b00;
    localparam MULTIPLY = 2'b01;
    localparam COMPLETE = 2'b10;
    reg [1:0] state, next_state;
    
    // Block 1: Symbol encoding logic (unchanged functionality)
    always @(*) begin
        case (symbol[3:0])
            4'h0: encoded_value = 4'h8;
            4'h1: encoded_value = 4'h9;
            4'h2: encoded_value = 4'hA;
            4'h3: encoded_value = 4'hB;
            4'h4: encoded_value = 4'hC;
            4'h5: encoded_value = 4'hD;
            4'h6: encoded_value = 4'hE;
            4'h7: encoded_value = 4'hF;
            4'h8: encoded_value = 4'h0;
            4'h9: encoded_value = 4'h1;
            4'hA: encoded_value = 4'h2;
            4'hB: encoded_value = 4'h3;
            4'hC: encoded_value = 4'h4;
            4'hD: encoded_value = 4'h5;
            4'hE: encoded_value = 4'h6;
            4'hF: encoded_value = 4'h7;
            default: encoded_value = 4'h0;
        endcase
    end
    
    // Block 2: Output control logic (unchanged)
    always @(*) begin
        if (valid_in) begin
            code = encoded_value;
            valid_out = 1'b1;
        end else begin
            code = 4'h0;
            valid_out = 1'b0;
        end
    end
    
    // Block 3: Sequential state machine for shift-and-add multiplier
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            mult_count <= 0;
            product <= 0;
            multiplier <= 0;
            multiplicand <= 0;
            mult_in_progress <= 0;
            mult_result <= 0;
            mult_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    mult_valid <= 0;
                    if (valid_in) begin
                        // Prepare for multiplication
                        multiplier <= symbol[3:0];    // Lower 4 bits
                        multiplicand <= symbol[7:4];  // Upper 4 bits
                        product <= 0;
                        mult_count <= 0;
                        mult_in_progress <= 1;
                        state <= MULTIPLY;
                    end
                end
                
                MULTIPLY: begin
                    if (mult_count < 4) begin
                        // Check the current bit of multiplier
                        if (multiplier[0]) begin
                            // Add shifted multiplicand to product
                            product <= product + (multiplicand << mult_count);
                        end
                        // Right shift multiplier to examine next bit
                        multiplier <= multiplier >> 1;
                        mult_count <= mult_count + 1;
                    end else begin
                        state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    mult_result <= product;
                    mult_valid <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule