//SystemVerilog
// Top-level module that instantiates the sub-modules with Valid-Ready handshake
module Demux_Priority #(parameter DW=4) (
    input clk,
    input rst_n,
    
    // Input interface with valid-ready handshake
    input [DW-1:0] data_in,
    input [3:0] sel,
    input data_in_valid,
    output data_in_ready,
    
    // Output interface with valid-ready handshake
    output [15:0][DW-1:0] data_out,
    output [15:0] data_out_valid,
    input [15:0] data_out_ready
);
    // Internal signals for priority detection
    wire [3:0] priority_level;
    wire [15:0] selected_output;
    
    // Handshake control signals
    reg data_processed;
    wire output_ready;
    
    // Generate output_ready signal - OR reduction of selected channel ready signals
    assign output_ready = |(selected_output & data_out_ready);
    
    // Input ready when we can process data
    assign data_in_ready = output_ready;
    
    // Output valid signals - only valid for the selected output channel
    assign data_out_valid = data_in_valid ? selected_output : 16'b0;
    
    // Instantiate priority encoder sub-module
    PriorityEncoder u_priority_encoder (
        .sel(sel),
        .priority_level(priority_level)
    );
    
    // Instantiate output selector sub-module
    OutputSelector #(.DW(DW)) u_output_selector (
        .data_in(data_in),
        .priority_level(priority_level),
        .selected_output(selected_output)
    );
    
    // Instantiate data distributor sub-module
    DataDistributor #(.DW(DW)) u_data_distributor (
        .data_in(data_in),
        .selected_output(selected_output),
        .data_in_valid(data_in_valid),
        .data_out_ready(data_out_ready),
        .data_out(data_out)
    );
endmodule

// Module to detect priority level from selection input
module PriorityEncoder (
    input [3:0] sel,
    output reg [3:0] priority_level
);
    always @(*) begin
        casez (sel)
            4'b1???: priority_level = 4'd15;
            4'b01??: priority_level = 4'd7;
            4'b001?: priority_level = 4'd3;
            4'b0001: priority_level = 4'd1;
            4'b0000: priority_level = 4'd0;
            default: priority_level = 4'd0;
        endcase
    end
endmodule

// Module to determine which output should be active
module OutputSelector #(parameter DW=4) (
    input [DW-1:0] data_in,
    input [3:0] priority_level,
    output reg [15:0] selected_output
);
    always @(*) begin
        selected_output = 16'b0;
        case (priority_level)
            4'd15: selected_output[15] = 1'b1;
            4'd7:  selected_output[7]  = 1'b1;
            4'd3:  selected_output[3]  = 1'b1;
            4'd1:  selected_output[1]  = 1'b1;
            4'd0:  selected_output[0]  = 1'b1;
            default: selected_output[0] = 1'b1;
        endcase
    end
endmodule

// Module to distribute data to the appropriate output channel with valid-ready handshake
module DataDistributor #(parameter DW=4) (
    input [DW-1:0] data_in,
    input [15:0] selected_output,
    input data_in_valid,
    input [15:0] data_out_ready,
    output reg [15:0][DW-1:0] data_out
);
    integer i;
    
    always @(*) begin
        // Initialize all outputs to zero
        for (i = 0; i < 16; i = i + 1) begin
            data_out[i] = {DW{1'b0}};
        end
        
        // Only distribute data when valid
        if (data_in_valid) begin
            for (i = 0; i < 16; i = i + 1) begin
                // Data is routed to selected output
                data_out[i] = selected_output[i] ? data_in : {DW{1'b0}};
            end
        end
    end
endmodule