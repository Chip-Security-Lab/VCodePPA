//SystemVerilog
// Top module
module variable_step_counter #(
    parameter STEP = 1
)(
    input wire clk,
    input wire rst,
    output wire [7:0] ring_reg
);

    // Internal signals for module connections
    wire [7:0] current_value;
    wire [7:0] next_value;

    // Instance of the register module to hold the current state
    counter_register u_counter_register (
        .clk(clk),
        .rst(rst),
        .next_value(next_value),
        .current_value(current_value)
    );

    // Instance of the rotation logic module
    rotation_logic #(
        .STEP(STEP)
    ) u_rotation_logic (
        .current_value(current_value),
        .next_value(next_value)
    );

    // Connect the output
    assign ring_reg = current_value;

endmodule

// Module for sequential register logic
module counter_register (
    input wire clk,
    input wire rst,
    input wire [7:0] next_value,
    output reg [7:0] current_value
);

    always @(posedge clk) begin
        if (rst)
            current_value <= 8'h01;
        else
            current_value <= next_value;
    end

endmodule

// Module for rotation calculation logic
module rotation_logic #(
    parameter STEP = 1
)(
    input wire [7:0] current_value,
    output wire [7:0] next_value
);

    // Implement the rotation calculation
    assign next_value = {current_value[STEP-1:0], current_value[7:STEP]};

endmodule