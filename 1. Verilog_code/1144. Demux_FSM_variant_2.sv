//SystemVerilog
//==============================================================================
// Module: Demux_FSM
// Description: A 1-to-4 demultiplexer with FSM control
// Standard: IEEE 1364-2005
//==============================================================================
module Demux_FSM #(parameter DW=8) (
    input clk, rst,
    input [1:0] state,
    input [DW-1:0] data,
    output reg [3:0][DW-1:0] out
);

// State definitions
localparam S0 = 2'b00;
localparam S1 = 2'b01;
localparam S2 = 2'b10;
localparam S3 = 2'b11;

// Registered data and state
reg [DW-1:0] reg_data;
reg [1:0] reg_state;

// Register input data and state
always @(posedge clk) begin
    if (rst) begin
        reg_data <= {DW{1'b0}};
        reg_state <= 2'b00;
    end
    else begin
        reg_data <= data;
        reg_state <= state;
    end
end

// Combined output control with registered inputs
always @(posedge clk) begin
    if (rst) begin
        out <= {(4*DW){1'b0}};
    end
    else begin
        // Default: maintain values
        out <= out;
        
        // Update specific channel based on registered state
        case (reg_state)
            S0: out[0] <= reg_data;
            S1: out[1] <= reg_data;
            S2: out[2] <= reg_data;
            S3: out[3] <= reg_data;
        endcase
    end
end

endmodule