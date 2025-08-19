//SystemVerilog
//IEEE 1364-2005 Verilog standard
module tristate_buffer (
    input  wire        clk,       // System clock
    input  wire        rst_n,     // Active low reset
    input  wire [15:0] data_in,   // Input data bus
    input  wire        oe,        // Output enable control signal
    output wire [15:0] data_out   // Output data bus with tri-state capability
);
    // Pipeline registers for improved timing and data flow
    reg [15:0] data_in_reg;       // Register for input data
    reg        oe_reg;            // Register for output enable

    // First pipeline stage - data input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 16'b0;
            oe_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            oe_reg <= oe;
        end
    end

    // Output tri-state buffer implementation with registered inputs
    // This creates a pipelined data path with better timing closure
    assign data_out = oe_reg ? data_in_reg : 16'bz;

    // Metadata for synthesis tools
    // synthesis attribute DRIVE_STRENGTH of data_out : signal is 12;
    // synthesis attribute SLEW_RATE of data_out : signal is "FAST";
    // synthesis attribute IOB of data_in_reg : signal is "TRUE";
    // synthesis attribute MAX_FANOUT of oe_reg : signal is 16;
    
endmodule