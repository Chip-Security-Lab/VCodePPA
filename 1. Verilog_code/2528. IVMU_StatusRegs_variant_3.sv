//SystemVerilog
// Module to buffer the input signal
module active_buffer #(parameter WIDTH = 8) (
    input clk,
    input rst,
    input [WIDTH-1:0] active_in,
    output reg [WIDTH-1:0] active_out
);

    always @(posedge clk) begin
        if (rst) begin
            active_out <= {WIDTH{1'b0}};
        end else begin
            active_out <= active_in;
        end
    end

endmodule

// Module to implement the sticky status register logic
// status_out[i] becomes 1 if active_buffered_in[i] is ever 1 since reset
module sticky_status_register #(parameter WIDTH = 8) (
    input clk,
    input rst,
    input [WIDTH-1:0] active_buffered_in,
    output reg [WIDTH-1:0] status_out
);

    always @(posedge clk) begin
        if (rst) begin
            status_out <= {WIDTH{1'b0}};
        end else begin
            status_out <= status_out | active_buffered_in;
        end
    end

endmodule

// Top module for IVMU Status Registers
// Decomposed into input buffering and sticky status update sub-modules
module IVMU_StatusRegs #(parameter CH=8) (
    input clk,
    input rst,
    input [CH-1:0] active,
    output logic [CH-1:0] status
);

    // Internal signal to connect the output of the buffer to the input of the status register
    logic [CH-1:0] active_buffered_sig;

    // Instantiate the active buffer module
    active_buffer #(
        .WIDTH(CH)
    ) active_buffer_inst (
        .clk(clk),
        .rst(rst),
        .active_in(active),
        .active_out(active_buffered_sig)
    );

    // Instantiate the sticky status register module
    sticky_status_register #(
        .WIDTH(CH)
    ) sticky_status_register_inst (
        .clk(clk),
        .rst(rst),
        .active_buffered_in(active_buffered_sig),
        .status_out(status)
    );

endmodule