//SystemVerilog
`timescale 1ns / 1ps
// IEEE 1364-2005 compliant

module MuxInputShift #(parameter W=4) (
    input clk,
    input [1:0] sel,
    input [W-1:0] d0, d1, d2, d3,
    output reg [W-1:0] q
);

    // Control signals logic
    reg shift_left, load_full;
    
    always @(*) begin
        shift_left = 1'b0;
        load_full = 1'b0;
        
        case (sel)
            2'b00, 2'b01: shift_left = 1'b1;
            2'b10: shift_left = 1'b0;
            2'b11: load_full = 1'b1;
            default: begin
                shift_left = 1'b0;
                load_full = 1'b0;
            end
        endcase
    end
    
    // Input data source selection
    reg [W-1:0] shift_data;
    
    always @(*) begin
        case (sel[0])
            1'b0: shift_data = d0;
            1'b1: shift_data = d1;
        endcase
    end
    
    // Next state computation
    reg [W-1:0] next_q;
    
    always @(*) begin
        if (load_full) begin
            next_q = d3;
        end
        else if (shift_left) begin
            next_q = {q[W-2:0], shift_data[0]};
        end
        else begin 
            next_q = {d2[0], q[W-1:1]};
        end
    end
    
    // Sequential update
    always @(posedge clk) begin
        q <= next_q;
    end

endmodule