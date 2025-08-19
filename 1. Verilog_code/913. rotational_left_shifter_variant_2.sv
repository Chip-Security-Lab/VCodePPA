//SystemVerilog
module rotational_left_shifter (
    input clock,
    input enable,
    input reset,
    input [15:0] data_input,
    input [3:0] rotate_amount,
    output reg [15:0] data_output
);

    // Internal signals for carry look-ahead based rotation
    reg [15:0] level1_data, level2_data, level3_data, level4_data;
    wire [15:0] rotated_data;
    
    // Level 1: Rotate by 0 or 1 position
    always @(*) begin
        level1_data = rotate_amount[0] ? {data_input[14:0], data_input[15]} : data_input;
    end
    
    // Level 2: Rotate by 0 or 2 positions
    always @(*) begin
        level2_data = rotate_amount[1] ? {level1_data[13:0], level1_data[15:14]} : level1_data;
    end
    
    // Level 3: Rotate by 0 or 4 positions
    always @(*) begin
        level3_data = rotate_amount[2] ? {level2_data[11:0], level2_data[15:12]} : level2_data;
    end
    
    // Level 4: Rotate by 0 or 8 positions
    always @(*) begin
        level4_data = rotate_amount[3] ? {level3_data[7:0], level3_data[15:8]} : level3_data;
    end
    
    // Final rotated output
    assign rotated_data = level4_data;
    
    // Output register control
    always @(posedge clock) begin
        if (reset) begin
            data_output <= 16'd0;
        end else if (enable) begin
            data_output <= rotated_data;
        end
    end

endmodule