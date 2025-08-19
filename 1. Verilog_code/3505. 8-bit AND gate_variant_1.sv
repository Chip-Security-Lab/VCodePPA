//SystemVerilog
//=============================================================================
// File Name: and_gate_8_top.v
// Description: Top level module for 8-bit AND operation with Req-Ack handshake
//=============================================================================

`timescale 1ns / 1ps
`default_nettype none

module and_gate_8 (
    input wire clk,                // Clock signal
    input wire rst_n,              // Active low reset
    input wire [7:0] a,            // 8-bit input A
    input wire [7:0] b,            // 8-bit input B
    input wire req_in,             // Request input signal
    output wire ack_out,           // Acknowledge output signal
    output wire [7:0] y,           // 8-bit output Y
    output wire req_out,           // Request output signal
    input wire ack_in              // Acknowledge input signal
);

    // Internal signals
    wire [3:0] lower_y, higher_y;
    reg [7:0] a_reg, b_reg;
    reg [7:0] y_reg;
    reg req_out_reg;
    reg processing;
    
    // Handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            y_reg <= 8'b0;
            req_out_reg <= 1'b0;
            processing <= 1'b0;
        end else begin
            // Input handshake
            if (req_in && !processing) begin
                a_reg <= a;
                b_reg <= b;
                processing <= 1'b1;
            end
            
            // Processing
            if (processing && !req_out_reg) begin
                y_reg <= {higher_y, lower_y};
                req_out_reg <= 1'b1;
            end
            
            // Output handshake completion
            if (req_out_reg && ack_in) begin
                req_out_reg <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
    
    // Acknowledge output generation
    assign ack_out = processing;
    
    // Request output
    assign req_out = req_out_reg;
    
    // Output assignment
    assign y = y_reg;

    // Instantiate lower bit group (0-3) AND operation module
    and_gate_4_bits lower_bits (
        .a_in(a_reg[3:0]),
        .b_in(b_reg[3:0]),
        .y_out(lower_y)
    );
    
    // Instantiate higher bit group (4-7) AND operation module
    and_gate_4_bits higher_bits (
        .a_in(a_reg[7:4]),
        .b_in(b_reg[7:4]),
        .y_out(higher_y)
    );

endmodule

//=============================================================================
// File Name: and_gate_4_bits.v
// Description: 4-bit AND operation submodule
//=============================================================================

module and_gate_4_bits (
    input wire [3:0] a_in,   // 4-bit input A
    input wire [3:0] b_in,   // 4-bit input B
    output wire [3:0] y_out  // 4-bit output Y
);

    // Instantiate individual bit AND operation modules
    and_gate_1_bit bit0 (
        .a_bit(a_in[0]),
        .b_bit(b_in[0]),
        .y_bit(y_out[0])
    );
    
    and_gate_1_bit bit1 (
        .a_bit(a_in[1]),
        .b_bit(b_in[1]),
        .y_bit(y_out[1])
    );
    
    and_gate_1_bit bit2 (
        .a_bit(a_in[2]),
        .b_bit(b_in[2]),
        .y_bit(y_out[2])
    );
    
    and_gate_1_bit bit3 (
        .a_bit(a_in[3]),
        .b_bit(b_in[3]),
        .y_bit(y_out[3])
    );

endmodule

//=============================================================================
// File Name: and_gate_1_bit.v
// Description: Single-bit AND operation primitive module
//=============================================================================

module and_gate_1_bit (
    input wire a_bit,   // 1-bit input A
    input wire b_bit,   // 1-bit input B
    output wire y_bit   // 1-bit output Y
);

    // Primitive AND operation
    assign y_bit = a_bit & b_bit;

endmodule

`default_nettype wire