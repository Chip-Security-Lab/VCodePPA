//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: ram_based_ring
// Description: A ring-based memory structure with hierarchical implementation
///////////////////////////////////////////////////////////////////////////////
module ram_based_ring #(
    parameter ADDR_WIDTH = 4
)(
    input wire clk,
    input wire rst,
    output wire [2**ADDR_WIDTH-1:0] ram_out
);
    // Internal signals for module communication
    wire [ADDR_WIDTH-1:0] addr_value;
    wire [2**ADDR_WIDTH-1:0] shift_out;

    // Address generator submodule instance
    addr_generator #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) addr_gen_inst (
        .clk(clk),
        .rst(rst),
        .addr_out(addr_value)
    );

    // Ring buffer logic - combines shifter and output functionality
    ring_buffer #(
        .WIDTH(2**ADDR_WIDTH)
    ) ring_buffer_inst (
        .clk(clk),
        .rst(rst),
        .ram_out(ram_out)
    );
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: addr_generator
// Description: Generates sequential addresses for the ring operation
///////////////////////////////////////////////////////////////////////////////
module addr_generator #(
    parameter ADDR_WIDTH = 4
)(
    input wire clk,
    input wire rst,
    output reg [ADDR_WIDTH-1:0] addr_out
);
    always @(posedge clk) begin
        if (rst) begin
            addr_out <= {ADDR_WIDTH{1'b0}};
        end else begin
            addr_out <= addr_out + 1'b1;
        end
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: ring_buffer
// Description: Unified implementation of shift register and output functionality
///////////////////////////////////////////////////////////////////////////////
module ring_buffer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    output reg [WIDTH-1:0] ram_out
);
    // Internal shift register
    reg [WIDTH-1:0] shift_reg;
    
    // Combined sequential logic for shift register and output operations
    always @(posedge clk) begin
        if (rst) begin
            // Initialize both registers with 1 at LSB
            shift_reg <= {{(WIDTH-1){1'b0}}, 1'b1};
            ram_out <= {{(WIDTH-1){1'b0}}, 1'b1};
        end else begin
            // Perform shift operation
            shift_reg <= {shift_reg[0], shift_reg[WIDTH-1:1]};
            // Update output register with shift register value
            ram_out <= shift_reg;
        end
    end
endmodule