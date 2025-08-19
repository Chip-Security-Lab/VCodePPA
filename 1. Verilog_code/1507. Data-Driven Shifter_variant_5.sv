//SystemVerilog
module data_driven_shifter #(
    parameter WIDTH = 8
)(
    input  wire             clk,        // System clock
    input  wire             rst,        // Synchronous reset
    input  wire             data_valid, // Data valid signal
    input  wire             serial_in,  // Serial input bit
    output wire [WIDTH-1:0] parallel_out // Parallel output data
);

    // Pipeline stage 1: Input capture register
    reg                serial_in_r;
    reg                data_valid_r;
    
    // Pipeline stage 2: Shift register datapath
    reg [WIDTH-1:0]    shift_data;
    
    // Combinational logic for shift operation
    wire [WIDTH-1:0]   next_shift_data;
    assign next_shift_data = {shift_data[WIDTH-2:0], serial_in_r};
    
    // Sequential logic for input registration
    always @(posedge clk) begin
        if (rst) begin
            serial_in_r  <= 1'b0;
            data_valid_r <= 1'b0;
        end else begin
            serial_in_r  <= serial_in;
            data_valid_r <= data_valid;
        end
    end
    
    // Sequential logic for shift register
    always @(posedge clk) begin
        if (rst) begin
            shift_data <= {WIDTH{1'b0}};
        end else if (data_valid_r) begin
            shift_data <= next_shift_data;
        end
    end
    
    // Output assignment
    assign parallel_out = shift_data;

endmodule