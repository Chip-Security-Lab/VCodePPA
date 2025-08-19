//SystemVerilog
// Top-level module
module preset_ring_counter(
    input wire clk,
    input wire rst,
    input wire preset,
    output wire [3:0] q
);
    // Internal signals
    wire [1:0] control_signals;
    
    // Control signals encoder submodule
    control_encoder control_unit (
        .rst(rst),
        .preset(preset),
        .control(control_signals)
    );
    
    // Counter state machine submodule
    counter_state_machine counter_unit (
        .clk(clk),
        .control(control_signals),
        .q(q)
    );
    
endmodule

// Control encoder submodule - handles control signal priority logic
module control_encoder(
    input wire rst,
    input wire preset,
    output reg [1:0] control
);
    always @(*) begin
        // Encode control signals with priority
        control = {rst, preset};
    end
endmodule

// Counter state machine submodule - handles state transitions
module counter_state_machine(
    input wire clk,
    input wire [1:0] control,
    output reg [3:0] q
);
    // State transition logic
    always @(posedge clk) begin
        case(control)
            2'b10, 2'b11: q <= 4'b0001; // Reset has highest priority
            2'b01:        q <= 4'b1000; // Preset condition
            2'b00:        q <= {q[2:0], q[3]}; // Normal operation
            default:      q <= 4'b0001; // Safety case
        endcase
    end
endmodule