//SystemVerilog
// SystemVerilog
module sparse_crossbar (
    input wire clock, reset,
    input wire [7:0] in_A, in_B, in_C, in_D,
    input wire [1:0] sel_X, sel_Y, sel_Z,
    output reg [7:0] out_X, out_Y, out_Z
);
    // Intermediate signals to reduce redundant muxing
    reg [7:0] mux_A_reg;
    
    // Output selection logic
    wire sel_X_isA = (sel_X == 2'b00);
    wire sel_X_isB = (sel_X == 2'b01);
    wire sel_X_isD = (sel_X == 2'b10);
    
    wire sel_Y_isA = (sel_Y == 2'b00);
    wire sel_Y_isB = (sel_Y == 2'b01);
    wire sel_Y_isC = (sel_Y == 2'b10);
    
    wire sel_Z_isA = (sel_Z == 2'b00);
    wire sel_Z_isC = (sel_Z == 2'b01);
    
    // Internal mux signals
    reg [7:0] mux_out_X;
    reg [7:0] mux_out_Y;
    reg [7:0] mux_out_Z;
    
    // Explicit multiplexer implementation
    always @(*) begin
        // X output multiplexer
        case (sel_X)
            2'b00:   mux_out_X = mux_A_reg;
            2'b01:   mux_out_X = in_B;
            2'b10:   mux_out_X = in_D;
            default: mux_out_X = 8'h00;
        endcase
        
        // Y output multiplexer
        case (sel_Y)
            2'b00:   mux_out_Y = mux_A_reg;
            2'b01:   mux_out_Y = in_B;
            2'b10:   mux_out_Y = in_C;
            default: mux_out_Y = 8'h00;
        endcase
        
        // Z output multiplexer
        case (sel_Z)
            2'b00:   mux_out_Z = mux_A_reg;
            2'b01:   mux_out_Z = in_C;
            default: mux_out_Z = 8'h00;
        endcase
    end
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            out_X <= 8'h00;
            out_Y <= 8'h00;
            out_Z <= 8'h00;
            mux_A_reg <= 8'h00;
        end else begin
            // Store input A for potential reuse across outputs
            mux_A_reg <= in_A;
            
            // Register outputs
            out_X <= mux_out_X;
            out_Y <= mux_out_Y;
            out_Z <= mux_out_Z;
        end
    end
endmodule