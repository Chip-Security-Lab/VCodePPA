//SystemVerilog
module rotational_left_shifter (
    input clock,
    input enable,
    input reset,
    input [15:0] data_input,
    input [3:0] rotate_amount,
    output reg [15:0] data_output
);
    // Split the rotation operation into two pipeline stages
    // Stage 1: Calculate the left shift and right shift components
    reg [15:0] left_shifted_data;
    reg [15:0] right_shifted_data;
    reg [3:0] rotate_amount_reg;
    reg enable_pipe;
    
    // Temporary wires for pre-registered calculations
    wire [15:0] left_shift_result = data_input << rotate_amount;
    wire [15:0] right_shift_result = data_input >> (16 - rotate_amount);
    
    // Pipeline Stage 1: Register the shift calculations
    always @(posedge clock) begin
        if (reset) begin
            left_shifted_data <= 16'd0;
            right_shifted_data <= 16'd0;
            rotate_amount_reg <= 4'd0;
            enable_pipe <= 1'b0;
        end
        else begin
            left_shifted_data <= left_shift_result;
            right_shifted_data <= right_shift_result;
            rotate_amount_reg <= rotate_amount;
            enable_pipe <= enable;
        end
    end
    
    // Stage 2: Combine the shifted components
    wire [15:0] rotated_data = left_shifted_data | right_shifted_data;
    
    // Final output stage
    always @(posedge clock) begin
        if (reset)
            data_output <= 16'd0;
        else if (enable_pipe)
            data_output <= rotated_data;
    end
endmodule