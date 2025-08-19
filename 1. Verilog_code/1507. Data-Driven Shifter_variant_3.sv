//SystemVerilog
module data_driven_shifter #(parameter WIDTH = 8) (
    input wire clk, rst,
    input wire data_valid,
    input wire serial_in,
    output wire [WIDTH-1:0] parallel_out
);
    // Pipeline registers for input signals
    reg serial_in_reg;
    reg data_valid_reg;
    
    // Main shift register
    reg [WIDTH-1:0] shift_data;
    
    // Register input signals for better timing
    always @(posedge clk) begin
        if (rst) begin
            serial_in_reg <= 1'b0;
            data_valid_reg <= 1'b0;
        end else begin
            serial_in_reg <= serial_in;
            data_valid_reg <= data_valid;
        end
    end
    
    // Implement shift register with pre-calculated next value
    // This balances the path by reducing the critical path length
    reg [WIDTH-1:0] next_shift_data;
    
    // Pre-calculate the next shift value
    always @(*) begin
        next_shift_data = {shift_data[WIDTH-2:0], serial_in_reg};
    end
    
    // Register the shift operation using pre-calculated value
    always @(posedge clk) begin
        if (rst)
            shift_data <= {WIDTH{1'b0}};
        else if (data_valid_reg)
            shift_data <= next_shift_data;
    end
    
    // Direct assignment to output
    assign parallel_out = shift_data;
endmodule