//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: status_buffer
// Description: Status buffer with clear and update functionality
//              Optimized with forward retiming technique
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module status_buffer (
    input  wire       clk,
    input  wire [7:0] status_in,
    input  wire       update,
    input  wire       clear,
    output wire [7:0] status_out
);
    // Register the control signals and input data
    reg [7:0] status_in_reg;
    reg       update_reg;
    reg       clear_reg;
    reg [7:0] status_buffer_reg;
    
    // Register inputs - moving registers forward
    always @(posedge clk) begin
        status_in_reg <= status_in;
        update_reg <= update;
        clear_reg <= clear;
    end
    
    // Combinational logic for status calculation moved after input registers
    wire [7:0] next_status;
    assign next_status = clear_reg  ? 8'b0 :
                         update_reg ? (status_buffer_reg | status_in_reg) : 
                                      status_buffer_reg;
    
    // Output register
    always @(posedge clk) begin
        status_buffer_reg <= next_status;
    end
    
    // Connect internal register to output
    assign status_out = status_buffer_reg;

endmodule