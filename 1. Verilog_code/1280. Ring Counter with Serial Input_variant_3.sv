//SystemVerilog
// Top-level module
module serial_in_ring_counter(
    input wire clk,
    input wire rst,
    input wire ser_in,
    output wire [3:0] count
);
    // Internal signals
    wire reset_value;
    wire [3:0] next_count;
    wire [3:0] current_count;
    
    // Submodule instantiations
    reset_logic reset_unit (
        .rst(rst),
        .reset_value(reset_value)
    );
    
    shift_logic shift_unit (
        .current_count(current_count),
        .ser_in(ser_in),
        .next_count(next_count)
    );
    
    count_register reg_unit (
        .clk(clk),
        .reset_value(reset_value),
        .next_count(next_count),
        .rst(rst),
        .current_count(current_count)
    );
    
    // Output assignment
    assign count = current_count;
    
endmodule

// Reset logic submodule
module reset_logic (
    input wire rst,
    output wire reset_value
);
    // Reset value is active when reset is asserted
    assign reset_value = rst;
endmodule

// Shift logic submodule
module shift_logic (
    input wire [3:0] current_count,
    input wire ser_in,
    output wire [3:0] next_count
);
    // Shift left and insert serial input at LSB
    assign next_count = {current_count[2:0], ser_in};
endmodule

// Count register submodule
module count_register (
    input wire clk,
    input wire reset_value,
    input wire [3:0] next_count,
    input wire rst,
    output reg [3:0] current_count
);
    // Register with synchronous reset
    always @(posedge clk) begin
        if (reset_value)
            current_count <= 4'b0001; // Reset value
        else
            current_count <= next_count; // Normal operation
    end
endmodule