//SystemVerilog
module ring_counter_bidirectional (
    input clk, dir, rst,
    output reg [3:0] shift_reg
);
    // Intermediate signals to capture retimed logic
    reg dir_reg;
    reg [3:0] next_shift_reg;
    
    // Register the direction control signal
    always @(posedge clk) begin
        if (rst)
            dir_reg <= 1'b0;
        else
            dir_reg <= dir;
    end
    
    // Combinational logic for next state calculation
    always @(*) begin
        if (dir_reg)
            next_shift_reg = {shift_reg[2:0], shift_reg[3]};
        else
            next_shift_reg = {shift_reg[0], shift_reg[3:1]};
    end
    
    // Output register - moved after the combinational logic
    always @(posedge clk) begin
        if (rst)
            shift_reg <= 4'b0001;
        else
            shift_reg <= next_shift_reg;
    end
    
endmodule