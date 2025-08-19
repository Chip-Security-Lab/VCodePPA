//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: neg_edge_shifter_top.sv
// Description: Top module for negative edge shift register with hierarchical design
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module neg_edge_shifter_top #(
    parameter WIDTH = 6
) (
    input  wire             neg_clk,
    input  wire             d_in,
    input  wire             rstn,
    output wire [WIDTH-1:0] q_out
);

    // Internal signals
    wire                data_valid;
    wire                processed_data;
    wire [WIDTH-1:0]    shift_reg_data;
    
    // Input processing with data validation
    data_conditioning #(
        .ENABLE_VALIDATION(1)
    ) u_data_conditioning (
        .neg_clk        (neg_clk),
        .d_in           (d_in),
        .rstn           (rstn),
        .data_valid     (data_valid),
        .processed_data (processed_data)
    );
    
    // Shift register core with parameterized width
    shift_register_core #(
        .WIDTH          (WIDTH),
        .SHIFT_DIRECTION("LEFT")
    ) u_shift_register (
        .neg_clk        (neg_clk),
        .data_in        (processed_data),
        .data_valid     (data_valid),
        .rstn           (rstn),
        .shift_reg_data (shift_reg_data)
    );
    
    // Output stage with optional inversion capability
    output_stage #(
        .WIDTH          (WIDTH),
        .INVERT_OUTPUT  (1'b0)
    ) u_output_stage (
        .neg_clk        (neg_clk),
        .shift_reg_data (shift_reg_data),
        .rstn           (rstn),
        .q_out          (q_out)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: data_conditioning.sv
// Description: Enhanced input processing with data validation
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module data_conditioning #(
    parameter ENABLE_VALIDATION = 0
) (
    input  wire neg_clk,
    input  wire d_in,
    input  wire rstn,
    output reg  data_valid,
    output wire processed_data
);

    // Optional input validation
    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn)
            data_valid <= 1'b0;
        else
            data_valid <= 1'b1; // In this implementation, all data is valid
                              // Could be expanded for real validation logic
    end

    // Direct data pass-through in this implementation
    // Could be expanded for filtering, debouncing, etc.
    assign processed_data = d_in;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: shift_register_core.sv
// Description: Enhanced shift register with configurable direction
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module shift_register_core #(
    parameter WIDTH          = 6,
    parameter SHIFT_DIRECTION = "LEFT" // "LEFT" or "RIGHT"
) (
    input  wire               neg_clk,
    input  wire               data_in,
    input  wire               data_valid,
    input  wire               rstn,
    output reg  [WIDTH-1:0]   shift_reg_data
);

    // Main shift register operation with direction control
    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn) begin
            shift_reg_data <= {WIDTH{1'b0}};
        end
        else if (data_valid) begin
            if (SHIFT_DIRECTION == "LEFT") begin
                // Shift left (MSB in first)
                shift_reg_data <= {data_in, shift_reg_data[WIDTH-1:1]};
            end
            else begin
                // Shift right (LSB in first)
                shift_reg_data <= {shift_reg_data[WIDTH-2:0], data_in};
            end
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: output_stage.sv
// Description: Enhanced output stage with optional inversion
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module output_stage #(
    parameter WIDTH         = 6,
    parameter INVERT_OUTPUT = 1'b0
) (
    input  wire              neg_clk,
    input  wire [WIDTH-1:0]  shift_reg_data,
    input  wire              rstn,
    output wire [WIDTH-1:0]  q_out
);

    // Registered output data
    reg [WIDTH-1:0] output_buffer;
    
    // Register the output for better timing
    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn)
            output_buffer <= {WIDTH{1'b0}};
        else
            output_buffer <= shift_reg_data;
    end
    
    // Conditional output inversion based on parameter
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_output
            assign q_out[i] = INVERT_OUTPUT ? ~output_buffer[i] : output_buffer[i];
        end
    endgenerate
    
endmodule