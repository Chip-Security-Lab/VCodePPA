//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: dynamic_width_shifter_top.v
// Description: Top module for dynamic width shifter with improved architecture
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module DynamicWidthShifter #(
    parameter MAX_WIDTH = 16
)(
    input wire clk,
    input wire [4:0] current_width,
    input wire serial_in,
    output wire serial_out
);

    // Internal signals
    wire [MAX_WIDTH-1:0] shift_data_out;
    wire [MAX_WIDTH-1:0] shift_data_buffered;
    wire serial_out_prebuf;
    
    // Instantiate shift register module
    ShiftRegister #(
        .WIDTH(MAX_WIDTH)
    ) shift_reg_inst (
        .clk(clk),
        .serial_in(serial_in),
        .shift_data(shift_data_out)
    );
    
    // Buffer for shift_data high fanout signal
    ShiftDataBuffer #(
        .WIDTH(MAX_WIDTH)
    ) shift_data_buffer_inst (
        .clk(clk),
        .shift_data_in(shift_data_out),
        .shift_data_out(shift_data_buffered)
    );
    
    // Instantiate dynamic tap selector module
    DynamicTapSelector #(
        .MAX_WIDTH(MAX_WIDTH)
    ) tap_selector_inst (
        .shift_data(shift_data_buffered),
        .current_width(current_width),
        .serial_out(serial_out_prebuf)
    );
    
    // Buffer for serial_out high fanout signal
    SerialOutBuffer serial_out_buffer_inst (
        .clk(clk),
        .serial_in(serial_out_prebuf),
        .serial_out(serial_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: shift_register.v
// Description: Handles the shifting operation of input data
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module ShiftRegister #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire serial_in,
    output reg [WIDTH-1:0] shift_data
);

    // Shift register implementation
    always @(posedge clk) begin
        shift_data <= {shift_data[WIDTH-2:0], serial_in};
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: shift_data_buffer.v
// Description: Buffers shift_data to reduce fanout load
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module ShiftDataBuffer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire [WIDTH-1:0] shift_data_in,
    output reg [WIDTH-1:0] shift_data_out
);

    // Hierarchical buffering for better load distribution
    reg [WIDTH-1:0] shift_data_stage1;
    
    // Two-stage buffering to distribute the load
    always @(posedge clk) begin
        shift_data_stage1 <= shift_data_in;
        shift_data_out <= shift_data_stage1;
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: serial_out_buffer.v
// Description: Buffers serial_out to reduce fanout load
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module SerialOutBuffer (
    input wire clk,
    input wire serial_in,
    output reg serial_out
);

    // Register to buffer the serial output
    always @(posedge clk) begin
        serial_out <= serial_in;
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: dynamic_tap_selector.v
// Description: Selects the appropriate tap based on current width
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module DynamicTapSelector #(
    parameter MAX_WIDTH = 16
)(
    input wire [MAX_WIDTH-1:0] shift_data,
    input wire [4:0] current_width,
    output reg serial_out
);

    // Dynamic tap selection logic
    always @(*) begin
        serial_out = shift_data[current_width-1];
    end

endmodule