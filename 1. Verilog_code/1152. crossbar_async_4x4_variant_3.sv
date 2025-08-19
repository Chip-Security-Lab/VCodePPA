//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File Name: crossbar_async_4x4.v
// Description: 4x4 Asynchronous Crossbar Switch with Hierarchical Structure
///////////////////////////////////////////////////////////////////////////////

module crossbar_async_4x4 #(
    parameter DATA_WIDTH = 8,  // Parameterized data width
    parameter PORT_COUNT = 4   // Parameterized port count
)(
    input  wire [DATA_WIDTH-1:0] data_in_0, data_in_1, data_in_2, data_in_3,
    input  wire [1:0] select_out_0, select_out_1, select_out_2, select_out_3,
    output wire [DATA_WIDTH-1:0] data_out_0, data_out_1, data_out_2, data_out_3
);
    // Internal connections
    wire [DATA_WIDTH-1:0] input_data_bus [0:PORT_COUNT-1];
    
    // Input stage - map input ports to the input data bus
    input_stage #(
        .DATA_WIDTH(DATA_WIDTH),
        .PORT_COUNT(PORT_COUNT)
    ) u_input_stage (
        .data_in_0(data_in_0),
        .data_in_1(data_in_1),
        .data_in_2(data_in_2),
        .data_in_3(data_in_3),
        .input_data_bus(input_data_bus)
    );
    
    // Output stage - generates all output ports
    output_stage #(
        .DATA_WIDTH(DATA_WIDTH),
        .PORT_COUNT(PORT_COUNT)
    ) u_output_stage (
        .input_data_bus(input_data_bus),
        .select_out_0(select_out_0),
        .select_out_1(select_out_1),
        .select_out_2(select_out_2),
        .select_out_3(select_out_3),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2),
        .data_out_3(data_out_3)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Input Stage Module - Prepares and buffers input data for crossbar switching
///////////////////////////////////////////////////////////////////////////////
module input_stage #(
    parameter DATA_WIDTH = 8,
    parameter PORT_COUNT = 4
)(
    input  wire [DATA_WIDTH-1:0] data_in_0, data_in_1, data_in_2, data_in_3,
    output wire [DATA_WIDTH-1:0] input_data_bus [0:PORT_COUNT-1]
);
    // Optional input buffering could be added here
    
    // Map input ports to input data bus with optional processing
    assign input_data_bus[0] = data_in_0;
    assign input_data_bus[1] = data_in_1;
    assign input_data_bus[2] = data_in_2;
    assign input_data_bus[3] = data_in_3;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Output Stage Module - Manages routing of data to all output ports
///////////////////////////////////////////////////////////////////////////////
module output_stage #(
    parameter DATA_WIDTH = 8,
    parameter PORT_COUNT = 4
)(
    input  wire [DATA_WIDTH-1:0] input_data_bus [0:PORT_COUNT-1],
    input  wire [1:0] select_out_0, select_out_1, select_out_2, select_out_3,
    output wire [DATA_WIDTH-1:0] data_out_0, data_out_1, data_out_2, data_out_3
);
    // Instantiate individual output mux modules for each output port
    output_port_mux #(
        .DATA_WIDTH(DATA_WIDTH),
        .PORT_COUNT(PORT_COUNT)
    ) u_output_port_0 (
        .input_data_bus(input_data_bus),
        .select(select_out_0),
        .data_out(data_out_0)
    );
    
    output_port_mux #(
        .DATA_WIDTH(DATA_WIDTH),
        .PORT_COUNT(PORT_COUNT)
    ) u_output_port_1 (
        .input_data_bus(input_data_bus),
        .select(select_out_1),
        .data_out(data_out_1)
    );
    
    output_port_mux #(
        .DATA_WIDTH(DATA_WIDTH),
        .PORT_COUNT(PORT_COUNT)
    ) u_output_port_2 (
        .input_data_bus(input_data_bus),
        .select(select_out_2),
        .data_out(data_out_2)
    );
    
    output_port_mux #(
        .DATA_WIDTH(DATA_WIDTH),
        .PORT_COUNT(PORT_COUNT)
    ) u_output_port_3 (
        .input_data_bus(input_data_bus),
        .select(select_out_3),
        .data_out(data_out_3)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Output Port Multiplexer Module - Implements switching for a single output
///////////////////////////////////////////////////////////////////////////////
module output_port_mux #(
    parameter DATA_WIDTH = 8,
    parameter PORT_COUNT = 4
)(
    input  wire [DATA_WIDTH-1:0] input_data_bus [0:PORT_COUNT-1],
    input  wire [1:0] select,
    output wire [DATA_WIDTH-1:0] data_out
);
    // Efficient multiplexer implementation with proper timing considerations
    reg [DATA_WIDTH-1:0] mux_data;
    
    // Implement multiplexer with explicit case statement for better synthesis
    always @(*) begin
        case(select)
            2'b00: mux_data = input_data_bus[0];
            2'b01: mux_data = input_data_bus[1];
            2'b10: mux_data = input_data_bus[2];
            2'b11: mux_data = input_data_bus[3];
            default: mux_data = {DATA_WIDTH{1'b0}}; // Safe default
        endcase
    end
    
    // Output assignment
    assign data_out = mux_data;
    
endmodule