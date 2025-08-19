//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: and_gate_reset_top.v
// Description: Top level module for 2-input AND gate with reset functionality
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module and_gate_reset_top #(
    parameter REGISTER_OUTPUTS = 1  // Parameterize to allow registered or combinational mode
)(
    input  wire clk,     // Clock signal (for registered mode)
    input  wire a,       // Input A
    input  wire b,       // Input B
    input  wire rst,     // Reset signal (active high)
    output wire y        // Output Y
);
    // Internal signals
    wire logic_out;
    
    // Instantiate the logical operation sub-module with optimized interface
    logic_operations_unit #(
        .OPERATION_TYPE("AND")  // Parameterized to support different logic operations
    ) logic_ops_inst (
        .in_a      (a),
        .in_b      (b),
        .out_logic (logic_out)
    );
    
    // Instantiate the reset control sub-module with advanced features
    reset_control_unit #(
        .REGISTER_OUTPUT(REGISTER_OUTPUTS)
    ) reset_ctrl_inst (
        .clk       (clk),
        .logic_in  (logic_out),
        .rst       (rst),
        .final_out (y)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: logic_operations_unit.v
// Description: Parameterized module that performs configurable logical operations
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module logic_operations_unit #(
    parameter OPERATION_TYPE = "AND" // Supported types: "AND", "OR", "XOR", "NAND"
)(
    input  wire in_a,      // First input
    input  wire in_b,      // Second input
    output wire out_logic  // Logic output
);
    // Pre-computed operation signals to reduce critical path
    wire and_result, or_result, xor_result, nand_result;
    
    // Compute all operations in parallel to balance path delays
    assign and_result  = in_a & in_b;
    assign or_result   = in_a | in_b;
    assign xor_result  = in_a ^ in_b;
    assign nand_result = ~and_result; // Reuse AND result to reduce logic depth
    
    // Select appropriate operation result via multiplexer
    // This approach provides more predictable timing across parameter changes
    reg out_mux;
    
    always @(*) begin
        case(OPERATION_TYPE)
            "AND":  out_mux = and_result;
            "OR":   out_mux = or_result;
            "XOR":  out_mux = xor_result;
            "NAND": out_mux = nand_result;
            default: out_mux = and_result; // Default to AND
        endcase
    end
    
    assign out_logic = out_mux;
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: reset_control_unit.v
// Description: Enhanced reset control with optimized output registration
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module reset_control_unit #(
    parameter REGISTER_OUTPUT = 1  // 1: registered output, 0: combinational
)(
    input  wire clk,       // Clock input (used only when REGISTER_OUTPUT=1)
    input  wire logic_in,  // Input from logic unit
    input  wire rst,       // Reset signal (active high)
    output wire final_out  // Final output with reset applied
);
    // Split reset path from data path to reduce critical path
    wire pre_reset_logic;
    
    // For registered mode, move the reset logic to the register stage
    // to reduce logic before flip-flop and improve timing margin
    generate
        if (REGISTER_OUTPUT) begin: output_reg
            reg reg_out;
            
            // Skip combinational reset for registered outputs
            // Apply reset directly in register to reduce path delay
            assign pre_reset_logic = logic_in;
            
            always @(posedge clk or posedge rst) begin
                if (rst)
                    reg_out <= 1'b0;
                else
                    reg_out <= pre_reset_logic;
            end
            
            assign final_out = reg_out;
        end else begin: output_comb
            // For combinational mode, reset is applied directly
            assign pre_reset_logic = rst ? 1'b0 : logic_in;
            assign final_out = pre_reset_logic;
        end
    endgenerate
endmodule