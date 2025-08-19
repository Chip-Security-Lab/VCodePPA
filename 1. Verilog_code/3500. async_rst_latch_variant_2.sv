//SystemVerilog
// Top-level module
module async_rst_latch #(
    parameter WIDTH = 8
)(
    input wire rst,
    input wire en,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] latch_out
);
    // Internal signals
    wire rst_active;
    wire [WIDTH-1:0] data_selected;
    
    // Reset detection submodule - detects active reset signal
    reset_control #(
        .WIDTH(WIDTH)
    ) u_reset_control (
        .rst(rst),
        .rst_active(rst_active)
    );
    
    // Data processing pipeline - handles data selection and latching
    data_processing_unit #(
        .WIDTH(WIDTH)
    ) u_data_processing (
        .en(en),
        .din(din),
        .rst_active(rst_active),
        .latch_out(latch_out)
    );
    
endmodule

// Improved reset control with configurable polarity
module reset_control #(
    parameter WIDTH = 8,
    parameter RST_ACTIVE_HIGH = 1
)(
    input wire rst,
    output wire rst_active
);
    // Configurable reset polarity for better reusability
    generate
        if (RST_ACTIVE_HIGH) begin : gen_active_high
            assign rst_active = rst;
        end else begin : gen_active_low
            assign rst_active = ~rst;
        end
    endgenerate
endmodule

// Consolidated data processing unit that combines selection and latching
module data_processing_unit #(
    parameter WIDTH = 8
)(
    input wire en,
    input wire [WIDTH-1:0] din,
    input wire rst_active,
    output wire [WIDTH-1:0] latch_out
);
    // Internal signal
    wire [WIDTH-1:0] data_selected;
    
    // Data selector instance
    data_selector #(
        .WIDTH(WIDTH)
    ) u_data_selector (
        .en(en),
        .din(din),
        .rst_active(rst_active),
        .data_out(data_selected)
    );
    
    // Output register with clock-free latching behavior
    output_register #(
        .WIDTH(WIDTH)
    ) u_output_register (
        .data_in(data_selected),
        .latch_out(latch_out)
    );
endmodule

// Enhanced data selector with proper tri-state control
module data_selector #(
    parameter WIDTH = 8
)(
    input wire en,
    input wire [WIDTH-1:0] din,
    input wire rst_active,
    output wire [WIDTH-1:0] data_out
);
    // Priority multiplexer: reset takes precedence, then enable signal
    // Use separate assignments for better synthesis
    reg [WIDTH-1:0] selected_data;
    
    always @(*) begin
        if (rst_active)
            selected_data = {WIDTH{1'b0}};
        else if (en)
            selected_data = din;
        else
            selected_data = {WIDTH{1'bz}};
    end
    
    assign data_out = selected_data;
endmodule

// Improved output register with optional synchronous behavior
module output_register #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] latch_out
);
    // Transparent latch behavior with optimized implementation
    always @(*) begin
        if (data_in !== {WIDTH{1'bz}}) begin
            latch_out = data_in;
        end
    end
endmodule