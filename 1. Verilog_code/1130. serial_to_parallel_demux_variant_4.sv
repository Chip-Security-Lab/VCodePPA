//SystemVerilog
module serial_to_parallel_demux (
    input  wire       clk,           // Clock signal
    input  wire       rst,           // Reset signal
    input  wire       serial_in,     // Serial data input
    input  wire       load_enable,   // Load control
    output wire [7:0] parallel_out   // Parallel output channels
);
    
    wire       serial_in_reg;        // Registered serial data
    wire       load_enable_reg;      // Registered load enable
    wire [2:0] bit_counter;          // Bit position counter
    
    // Input registration module
    input_register input_reg_inst (
        .clk          (clk),
        .rst          (rst),
        .serial_in    (serial_in),
        .load_enable  (load_enable),
        .serial_out   (serial_in_reg),
        .load_out     (load_enable_reg)
    );
    
    // Bit counter module
    bit_counter_module bit_counter_inst (
        .clk          (clk),
        .rst          (rst),
        .load_enable  (load_enable_reg),
        .bit_count    (bit_counter)
    );
    
    // Data loader module
    data_loader data_loader_inst (
        .clk          (clk),
        .rst          (rst),
        .serial_in    (serial_in_reg),
        .load_enable  (load_enable_reg),
        .bit_pos      (bit_counter),
        .parallel_out (parallel_out)
    );
    
endmodule


// Module for registering input signals to reduce input-to-register delay
module input_register (
    input  wire clk,
    input  wire rst,
    input  wire serial_in,
    input  wire load_enable,
    output reg  serial_out,
    output reg  load_out
);
    
    always @(posedge clk) begin
        if (rst) begin
            serial_out <= 1'b0;
            load_out <= 1'b0;
        end else begin
            serial_out <= serial_in;
            load_out <= load_enable;
        end
    end
    
endmodule


// Module for tracking bit position
module bit_counter_module (
    input  wire       clk,
    input  wire       rst,
    input  wire       load_enable,
    output reg  [2:0] bit_count
);
    
    always @(posedge clk) begin
        if (rst) begin
            bit_count <= 3'b0;
        end else if (load_enable) begin
            bit_count <= bit_count + 1'b1;
        end
    end
    
endmodule


// Module for loading serial data into parallel output
module data_loader (
    input  wire       clk,
    input  wire       rst,
    input  wire       serial_in,
    input  wire       load_enable,
    input  wire [2:0] bit_pos,
    output reg  [7:0] parallel_out
);
    
    always @(posedge clk) begin
        if (rst) begin
            parallel_out <= 8'b0;
        end else if (load_enable) begin
            parallel_out[bit_pos] <= serial_in;
        end
    end
    
endmodule