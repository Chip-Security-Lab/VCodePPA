//SystemVerilog
//-----------------------------------------------------------------------------
// File: priority_encoder_system.v
// Top-level module for priority encoding system
//-----------------------------------------------------------------------------
module priority_recovery (
    input wire clk,
    input wire enable,
    input wire [7:0] signals,
    output wire [2:0] recovered_idx,
    output wire valid
);
    // Internal signals
    wire [2:0] priority_index;
    wire signal_present;
    
    // Instantiate priority encoder for combinational logic
    priority_encoder priority_encoder_inst (
        .signals(signals),
        .index(priority_index),
        .valid(signal_present)
    );
    
    // Instantiate output register stage for sequential logic
    output_register output_register_inst (
        .clk(clk),
        .enable(enable),
        .index_in(priority_index),
        .valid_in(signal_present),
        .index_out(recovered_idx),
        .valid_out(valid)
    );
    
endmodule

//-----------------------------------------------------------------------------
// Priority Encoder Module - Handles the combinational priority encoding logic
//-----------------------------------------------------------------------------
module priority_encoder (
    input wire [7:0] signals,
    output reg [2:0] index,
    output wire valid
);
    // Signal presence detection
    assign valid = |signals;
    
    // Purely combinational priority encoder using if-else structure
    always @(*) begin
        if (signals[7]) begin
            index = 3'd7;
        end
        else if (signals[6]) begin
            index = 3'd6;
        end
        else if (signals[5]) begin
            index = 3'd5;
        end
        else if (signals[4]) begin
            index = 3'd4;
        end
        else if (signals[3]) begin
            index = 3'd3;
        end
        else if (signals[2]) begin
            index = 3'd2;
        end
        else if (signals[1]) begin
            index = 3'd1;
        end
        else if (signals[0]) begin
            index = 3'd0;
        end
        else begin
            index = 3'd0;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Output Register Module - Manages the synchronous output stage
//-----------------------------------------------------------------------------
module output_register (
    input wire clk,
    input wire enable,
    input wire [2:0] index_in,
    input wire valid_in,
    output reg [2:0] index_out,
    output reg valid_out
);
    // Registered outputs with enable control using if-else structure
    always @(posedge clk) begin
        if (enable) begin
            index_out <= index_in;
            valid_out <= valid_in;
        end
        else begin
            valid_out <= 1'b0;
            // Index remains unchanged when not enabled
        end
    end
endmodule