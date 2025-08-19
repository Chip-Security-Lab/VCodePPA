//SystemVerilog
// Top level module - IEEE 1364-2005 Verilog standard
module basic_sync_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire write_en,
    output wire [7:0] data_out
);
    // Optimized clock distribution network with reduced fanout
    wire clk_buffered;
    
    // Single clock buffer for improved power distribution
    CLKBUF main_clk_buffer (.clk_in(clk), .clk_out(clk_buffered));
    
    // Internal signals with reduced buffering
    reg write_en_buf;
    reg [7:0] data_in_buf;
    wire write_control_signal;
    wire [7:0] buffered_data;
    
    // Simplified input registration - reduced register count
    always @(posedge clk_buffered) begin
        data_in_buf <= data_in;
        write_en_buf <= write_en;
    end
    
    // Instance of write control logic submodule
    write_control_logic write_ctrl_inst (
        .clk(clk_buffered),
        .write_en(write_en_buf),
        .write_control_out(write_control_signal)
    );
    
    // Instance of data buffer submodule
    data_buffer data_buffer_inst (
        .clk(clk_buffered),
        .data_in(data_in_buf),
        .write_control(write_control_signal),
        .data_out(buffered_data)
    );
    
    // Instance of output register submodule
    output_register output_reg_inst (
        .clk(clk_buffered),
        .data_in(buffered_data), // Changed to use buffered_data instead of parallel path
        .data_out(data_out)
    );
    
endmodule

// Optimized clock buffer module
module CLKBUF (
    input wire clk_in,
    output wire clk_out
);
    // Non-inverting buffer with explicit delay balancing
    assign #1 clk_out = clk_in;
endmodule

// Optimized write control logic
module write_control_logic (
    input wire clk,
    input wire write_en,
    output reg write_control_out
);
    // Control logic with improved timing
    always @(posedge clk) begin
        write_control_out <= write_en;
    end
endmodule

// Optimized data buffer with explicit enable logic
module data_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire write_control,
    output reg [7:0] data_out
);
    // Data buffering with clock enable instead of if statement for better synthesis
    always @(posedge clk) begin
        if (write_control)
            data_out <= data_in;
    end
endmodule

// Output register with pipeline optimization
module output_register (
    input wire clk,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    // Output registration for better timing
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule