//SystemVerilog
// Top level module for AND gate with enable, featuring optimized data path
module and_gate_enable #(
    parameter PIPELINE_STAGES = 2,    // Configurable pipeline depth
    parameter GATE_DELAY = 0,         // AND gate delay
    parameter CTRL_DELAY = 0          // Control logic delay
)(
    input  wire clk,       // Clock input (added for pipelining)
    input  wire rst_n,     // Active-low reset (added for pipeline control)
    input  wire a,         // Input A
    input  wire b,         // Input B
    input  wire enable,    // Enable signal
    output wire y          // Output Y
);
    // Pipeline stage signals
    wire and_result_raw;          // Raw AND result
    reg  and_result_stage1;       // First pipeline stage
    reg  enable_stage1;           // Synchronized enable
    wire data_out_combinational;  // Pre-output combinational signal
    reg  data_out_registered;     // Registered output

    // === STAGE 0: Input Computation Layer ===
    // Basic AND operation with parameterized delay
    basic_and_gate #(
        .GATE_DELAY(GATE_DELAY)
    ) and_gate_inst (
        .in_a(a),
        .in_b(b),
        .out_y(and_result_raw)
    );

    // === STAGE 1: Mid-Pipeline Registration ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_stage1 <= 1'b0;
            enable_stage1 <= 1'b0;
        end else begin
            and_result_stage1 <= and_result_raw;
            enable_stage1 <= enable;
        end
    end

    // === STAGE 2: Output Control Layer ===
    // Generate controlled output signal based on synchronized enable
    output_control #(
        .CTRL_DELAY(CTRL_DELAY)
    ) ctrl_inst (
        .data_in(and_result_stage1),
        .enable(enable_stage1),
        .data_out(data_out_combinational)
    );

    // === STAGE 3: Output Registration ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_registered <= 1'b0;
        end else begin
            data_out_registered <= data_out_combinational;
        end
    end

    // Output multiplexer based on pipeline configuration
    generate
        if (PIPELINE_STAGES == 0) begin : NO_PIPELINE
            assign y = data_out_combinational;
        end else begin : WITH_PIPELINE
            assign y = data_out_registered;
        end
    endgenerate
endmodule

// Sub-module for basic AND operation with optimized timing
module basic_and_gate #(
    parameter GATE_DELAY = 0    // Configurable delay for timing adjustment
)(
    input  wire in_a,    // First input
    input  wire in_b,    // Second input
    output wire out_y    // AND result output
);
    // Optimized AND operation with controlled delay
    assign #(GATE_DELAY) out_y = in_a & in_b;
endmodule

// Sub-module for output control with timing optimization
module output_control #(
    parameter CTRL_DELAY = 0    // Configurable delay for timing control
)(
    input  wire data_in,     // Input data
    input  wire enable,      // Enable control signal
    output wire data_out     // Controlled output
);
    // Optimized control logic with configurable delay
    assign #(CTRL_DELAY) data_out = enable ? data_in : 1'b0;
endmodule