//SystemVerilog
module ring_counter_bidirectional (
    input clk, dir, rst,
    output [3:0] shift_reg
);
    // Direction information captured in registers
    reg dir_reg;
    // Output registers with different shift patterns
    reg [3:0] shift_reg_right;
    reg [3:0] shift_reg_left;
    
    // Register the direction control
    always @(posedge clk) begin
        if (rst)
            dir_reg <= 1'b0;
        else
            dir_reg <= dir;
    end
    
    // Right shift register
    always @(posedge clk) begin
        if (rst)
            shift_reg_right <= 4'b0001;
        else
            shift_reg_right <= {shift_reg_right[2:0], shift_reg_right[3]};
    end
    
    // Left shift register
    always @(posedge clk) begin
        if (rst)
            shift_reg_left <= 4'b0001;
        else
            shift_reg_left <= {shift_reg_left[0], shift_reg_left[3:1]};
    end
    
    // Select output based on registered direction
    assign shift_reg = dir_reg ? shift_reg_right : shift_reg_left;
    
endmodule