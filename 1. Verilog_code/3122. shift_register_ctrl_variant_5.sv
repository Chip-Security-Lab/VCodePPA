//SystemVerilog
module shift_register_ctrl(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [1:0] shift_mode, // 00:none, 01:left, 10:right, 11:rotate
    input wire serial_in,
    input wire parallel_load,
    input wire [7:0] parallel_data,
    output reg [7:0] data_out,
    output reg serial_out
);
    parameter [1:0] IDLE = 2'b00, LOAD = 2'b01, 
                    SHIFT = 2'b10, OUTPUT = 2'b11;
    reg [1:0] state, next_state;
    reg [7:0] shift_register;
    
    // New signals for the multiplier
    reg [7:0] multiplicand;
    reg [7:0] multiplier;
    reg [15:0] product; // To hold the result of multiplication
    reg [3:0] count; // Counter for the number of bits

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            shift_register <= 8'd0;
            data_out <= 8'd0;
            serial_out <= 1'b0;
            product <= 16'd0;
            count <= 4'd0;
        end else begin
            state <= next_state;
            
            if (state == IDLE) begin
                // Hold current values
            end else if (state == LOAD) begin
                shift_register <= parallel_data;
                multiplicand <= parallel_data; // Load multiplicand
                multiplier <= 8'd2; // Example multiplier, can be set as needed
                product <= 16'd0; // Reset product
                count <= 4'd8; // Set count to 8 for 8-bit multiplication
            end else if (state == SHIFT) begin
                if (multiplier[0]) begin
                    product <= product + multiplicand; // Add if LSB of multiplier is 1
                end
                multiplicand <= {multiplicand[6:0], 1'b0}; // Shift multiplicand left
                multiplier <= {1'b0, multiplier[7:1]}; // Shift multiplier right
                count <= count - 1; // Decrement count
            end else if (state == OUTPUT) begin
                data_out <= product[7:0]; // Output lower 8 bits of product
            end
        end
    end
    
    always @(*) begin
        if (state == IDLE) begin
            if (parallel_load)
                next_state = LOAD;
            else if (enable && shift_mode != 2'b00)
                next_state = SHIFT;
            else
                next_state = IDLE;
        end else if (state == LOAD) begin
            next_state = OUTPUT;
        end else if (state == SHIFT) begin
            if (count > 0)
                next_state = SHIFT; // Stay in SHIFT until done
            else
                next_state = OUTPUT;
        end else if (state == OUTPUT) begin
            if (parallel_load)
                next_state = LOAD;
            else if (enable && shift_mode != 2'b00)
                next_state = SHIFT;
            else
                next_state = IDLE;
        end else begin
            next_state = IDLE;
        end
    end
endmodule