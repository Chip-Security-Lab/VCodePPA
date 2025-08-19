module sparse_crossbar (
    input wire clock, reset,
    input wire [7:0] in_A, in_B, in_C, in_D,
    input wire [1:0] sel_X, sel_Y, sel_Z,
    output reg [7:0] out_X, out_Y, out_Z
);
    // Sparse crossbar where not all inputs connect to all outputs
    // Input A connects to outputs X, Y, Z
    // Input B connects to outputs X, Y
    // Input C connects to outputs Y, Z
    // Input D connects to output X only
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            out_X <= 8'h00;
            out_Y <= 8'h00;
            out_Z <= 8'h00;
        end else begin
            // Output X can select from A, B, or D
            case (sel_X)
                2'b00: out_X <= in_A;
                2'b01: out_X <= in_B;
                2'b10: out_X <= in_D;
                default: out_X <= 8'h00;
            endcase
            
            // Output Y can select from A, B, or C
            case (sel_Y)
                2'b00: out_Y <= in_A;
                2'b01: out_Y <= in_B;
                2'b10: out_Y <= in_C;
                default: out_Y <= 8'h00;
            endcase
            
            // Output Z can select from A or C
            case (sel_Z)
                2'b00: out_Z <= in_A;
                2'b01: out_Z <= in_C;
                default: out_Z <= 8'h00;
            endcase
        end
    end
endmodule