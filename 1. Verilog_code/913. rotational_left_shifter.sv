module rotational_left_shifter (
    input clock,
    input enable,
    input reset,
    input [15:0] data_input,
    input [3:0] rotate_amount,
    output reg [15:0] data_output
);
    // Temporary wire for rotation calculation
    wire [15:0] rotated_data;
    
    // Corrected implementation for left rotation
    // A left rotation combines left shift of data with wrapped-around bits from the right
    assign rotated_data = (data_input << rotate_amount) | (data_input >> (16 - rotate_amount));
    
    // Register output with synchronous reset and enable
    always @(posedge clock) begin
        if (reset)
            data_output <= 16'd0;
        else if (enable)
            data_output <= rotated_data;
    end
endmodule