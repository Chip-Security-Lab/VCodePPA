//SystemVerilog
module sync_shift_rst #(
    parameter DEPTH = 4
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             serial_in,
    output wire [DEPTH-1:0] shift_reg
);
    // Internal pipeline registers for improved timing and data flow clarity
    reg             serial_in_r;          // Input stage register
    reg [DEPTH-1:0] shift_reg_internal;   // Shift register internal implementation
    reg [DEPTH-1:0] shift_reg_output;     // Output stage register
    
    // Input stage - register the incoming serial data
    always @(posedge clk) begin
        if (rst) begin
            serial_in_r <= 1'b0;
        end else begin
            serial_in_r <= serial_in;
        end
    end
    
    // Processing stage - main shift register operation
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_internal <= {DEPTH{1'b0}};
        end else begin
            // Optimized shift operation with registered input
            shift_reg_internal <= {shift_reg_internal[DEPTH-2:0], serial_in_r};
        end
    end
    
    // Output stage - register outputs for improved timing
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_output <= {DEPTH{1'b0}};
        end else begin
            shift_reg_output <= shift_reg_internal;
        end
    end
    
    // Connect internal register to output port
    assign shift_reg = shift_reg_output;

endmodule