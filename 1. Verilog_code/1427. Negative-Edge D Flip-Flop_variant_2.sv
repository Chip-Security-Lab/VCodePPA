//SystemVerilog
// Top module - manages the overall D flip-flop functionality
module neg_edge_d_ff (
    input  wire clk,
    input  wire d_in,
    output wire q_out
);
    // Internal signals
    wire captured_data;
    
    // Submodule instantiation
    data_capture_unit data_capture (
        .clk_in       (clk),
        .data_in      (d_in),
        .captured_data(captured_data)
    );
    
    // Output assignment
    output_buffer output_buf (
        .data_in (captured_data),
        .data_out(q_out)
    );
    
endmodule

// Submodule for data capture on negative clock edge
module data_capture_unit (
    input  wire clk_in,
    input  wire data_in,
    output reg  captured_data
);
    // Capture data on negative edge of clock
    always @(negedge clk_in) begin
        captured_data <= data_in;
    end
endmodule

// Submodule for output buffering
module output_buffer (
    input  wire data_in,
    output wire data_out
);
    // Simple buffering of the data
    assign data_out = data_in;
endmodule