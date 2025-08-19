//SystemVerilog - IEEE 1364-2005
// Top level module for three-input AND operation
// Implements a parameterized hierarchical triple-input AND gate
module Triple_AND_Hierarchical #(
    parameter PIPELINE_STAGES = 1,  // Configurable pipeline stages for timing optimization
    parameter GATE_TYPE = "AND"     // Configurable gate type (future expansion)
)(
    input  logic clk,               // Clock input for registered version
    input  logic rst_n,             // Active-low reset
    input  logic en,                // Enable signal
    input  logic a, b, c,           // Three inputs for AND operation
    output logic out                // Final output
);
    // Internal signals with bus structure for easier management
    logic [PIPELINE_STAGES:0] stage_results;
    
    // Control logic for global control signals
    Control_Unit #(
        .PIPELINE_STAGES(PIPELINE_STAGES)
    ) control_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .gate_active(stage_results[0])  // First stage result as activity indicator
    );
    
    // First stage logic computation
    Input_Processing_Stage #(
        .GATE_TYPE(GATE_TYPE)
    ) first_stage_inst (
        .in1(a),
        .in2(b),
        .out(stage_results[0])
    );
    
    // Second stage logic computation
    Output_Processing_Stage #(
        .PIPELINE_STAGES(PIPELINE_STAGES),
        .GATE_TYPE(GATE_TYPE)
    ) second_stage_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .in1(stage_results[0]),
        .in2(c),
        .out(out)
    );
endmodule

// Control unit for managing pipeline stages and control signals
module Control_Unit #(
    parameter PIPELINE_STAGES = 1
)(
    input  logic clk,
    input  logic rst_n,
    input  logic en,
    input  logic gate_active
);
    // Control logic for power optimization
    // (Currently a placeholder for future power management features)
endmodule

// First stage processes first two inputs
module Input_Processing_Stage #(
    parameter GATE_TYPE = "AND"
)(
    input  logic in1, in2,
    output logic out
);
    // Logic operation based on gate type parameter
    generate
        if (GATE_TYPE == "AND") begin : gen_and_gate
            assign out = in1 & in2;
        end
        else begin : gen_default
            assign out = in1 & in2; // Default to AND operation
        end
    endgenerate
endmodule

// Final stage processes intermediate result with third input
// Includes optional pipelining for timing optimization
module Output_Processing_Stage #(
    parameter PIPELINE_STAGES = 1,
    parameter GATE_TYPE = "AND"
)(
    input  logic clk,
    input  logic rst_n,
    input  logic en,
    input  logic in1, in2,
    output logic out
);
    logic intermediate_result;
    
    // Main logic operation
    generate
        if (GATE_TYPE == "AND") begin : gen_and_gate
            assign intermediate_result = in1 & in2;
        end
        else begin : gen_default
            assign intermediate_result = in1 & in2; // Default to AND operation
        end
    endgenerate
    
    // Configurable pipeline implementation
    generate
        if (PIPELINE_STAGES > 0) begin : gen_pipeline
            // Registered output for improved timing
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    out <= 1'b0;
                end
                else if (en) begin
                    out <= intermediate_result;
                end
            end
        end
        else begin : gen_no_pipeline
            // Combinational path for low-latency operation
            assign out = intermediate_result;
        end
    endgenerate
endmodule