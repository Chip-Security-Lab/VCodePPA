//SystemVerilog
/////////////////////////////////////////////////////////
// File: and_gate_top.v
// Description: Parameterized AND gate with configurable 
//              delay and drive strength
// Standard: IEEE 1364-2005
/////////////////////////////////////////////////////////

`timescale 1ns/1ps

module and_gate_top #(
    parameter DELAY_PS = 0,      // Configurable delay in picoseconds
    parameter OUTPUT_REG = 0      // 0: Combinational, 1: Registered output
) (
    input wire a,                // Input A
    input wire b,                // Input B
    input wire clk,              // Clock (used only if OUTPUT_REG=1)
    output wire y                // Output Y
);

    // Internal signals
    wire logic_output;
    reg a_reg, b_reg;
    
    // Register inputs when output is registered (retiming optimization)
    generate
        if (OUTPUT_REG == 1) begin: g_input_reg
            always @(posedge clk) begin
                a_reg <= a;
                b_reg <= b;
            end
            
            // Instantiate logic core module with registered inputs
            and_gate_logic_core logic_inst (
                .a(a_reg),
                .b(b_reg),
                .y(logic_output)
            );
        end else begin: g_no_input_reg
            // Instantiate logic core module with direct inputs
            and_gate_logic_core logic_inst (
                .a(a),
                .b(b),
                .y(logic_output)
            );
        end
    endgenerate
    
    // Instantiate output stage
    and_gate_output_stage #(
        .DELAY_PS(DELAY_PS),
        .OUTPUT_REG(OUTPUT_REG)
    ) output_inst (
        .logic_out(logic_output),
        .clk(clk),
        .y(y)
    );

endmodule

/////////////////////////////////////////////////////////
// Logic core module - implements the basic AND function
/////////////////////////////////////////////////////////
module and_gate_logic_core (
    input wire a,    // Input A
    input wire b,    // Input B
    output wire y    // Output Y
);
    
    // Basic AND operation
    assign y = a & b;
    
endmodule

/////////////////////////////////////////////////////////
// Output stage module - handles timing and output control
/////////////////////////////////////////////////////////
module and_gate_output_stage #(
    parameter DELAY_PS = 0,      // Configurable delay in picoseconds
    parameter OUTPUT_REG = 0      // 0: Combinational, 1: Registered output
) (
    input wire logic_out,        // Input from logic core
    input wire clk,              // Clock input
    output wire y                // Final output
);
    
    // Internal signals
    wire delayed_out;
    
    // Apply configurable delay if needed
    generate
        if (DELAY_PS > 0) begin: g_delay
            assign #(DELAY_PS * 1ps) delayed_out = logic_out;
        end else begin: g_no_delay
            assign delayed_out = logic_out;
        end
    endgenerate
    
    // Output assignment based on configuration
    // Retimed implementation - when OUTPUT_REG=1, the register has been 
    // moved to the inputs in the top module, so we use direct assignment here
    assign y = delayed_out;
    
endmodule