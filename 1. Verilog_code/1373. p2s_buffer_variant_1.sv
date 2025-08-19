//SystemVerilog
// Top-level module
module p2s_buffer (
    input wire clk,
    input wire load,
    input wire shift,
    input wire [7:0] parallel_in,
    output wire serial_out
);
    // Internal connections
    wire [7:0] current_data;
    wire [7:0] next_data;
    
    // Register unit instantiation (sequential logic)
    register_unit reg_unit (
        .clk(clk),
        .next_data(next_data),
        .current_data(current_data)
    );
    
    // Control logic unit instantiation (combinational logic)
    control_logic ctrl_logic (
        .load(load),
        .shift(shift),
        .parallel_in(parallel_in),
        .current_data(current_data),
        .next_data(next_data)
    );
    
    // Output logic unit instantiation (combinational logic)
    output_logic out_logic (
        .current_data(current_data),
        .serial_out(serial_out)
    );
    
endmodule

// Register unit module (purely sequential logic)
module register_unit (
    input wire clk,
    input wire [7:0] next_data,
    output reg [7:0] current_data
);
    always @(posedge clk) begin
        current_data <= next_data;
    end
endmodule

// Control logic module (purely combinational logic)
module control_logic (
    input wire load,
    input wire shift,
    input wire [7:0] parallel_in,
    input wire [7:0] current_data,
    output wire [7:0] next_data
);
    // Combinational logic using assign statement
    assign next_data = load ? parallel_in :
                      (shift ? {current_data[6:0], 1'b0} : current_data);
endmodule

// Output logic module (purely combinational logic)
module output_logic (
    input wire [7:0] current_data,
    output wire serial_out
);
    // Simple combinational logic using assign statement
    assign serial_out = current_data[7];
endmodule