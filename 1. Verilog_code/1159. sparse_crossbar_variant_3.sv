//SystemVerilog
module sparse_crossbar (
    input wire clock, reset,
    input wire [7:0] in_A, in_B, in_C, in_D,
    input wire [1:0] sel_X, sel_Y, sel_Z,
    output reg [7:0] out_X, out_Y, out_Z
);
    // Buffered high fanout signals
    reg [7:0] in_A_buf1, in_A_buf2, in_A_buf3;
    reg [7:0] next_out_X_buf1, next_out_X_buf2;
    reg [7:0] next_out_Y_buf1, next_out_Y_buf2;
    reg [7:0] next_out_Z_buf1, next_out_Z_buf2;
    reg [7:0] h00_buf1, h00_buf2;
    
    // Pre-computed mux outputs to reduce critical path
    wire [7:0] next_out_X, next_out_Y, next_out_Z;
    
    // Buffer high fanout signals in the sequential domain
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset all buffers
            in_A_buf1 <= 8'h00;
            in_A_buf2 <= 8'h00;
            in_A_buf3 <= 8'h00;
            next_out_X_buf1 <= 8'h00;
            next_out_X_buf2 <= 8'h00;
            next_out_Y_buf1 <= 8'h00;
            next_out_Y_buf2 <= 8'h00;
            next_out_Z_buf1 <= 8'h00;
            next_out_Z_buf2 <= 8'h00;
            h00_buf1 <= 8'h00;
            h00_buf2 <= 8'h00;
        end else begin
            // Buffer in_A signal for different paths
            in_A_buf1 <= in_A;
            in_A_buf2 <= in_A;
            in_A_buf3 <= in_A;
            
            // Buffer next_out signals
            next_out_X_buf1 <= next_out_X;
            next_out_X_buf2 <= next_out_X_buf1;
            next_out_Y_buf1 <= next_out_Y;
            next_out_Y_buf2 <= next_out_Y_buf1;
            next_out_Z_buf1 <= next_out_Z;
            next_out_Z_buf2 <= next_out_Z_buf1;
            
            // Buffer constant value 8'h00
            h00_buf1 <= 8'h00;
            h00_buf2 <= h00_buf1;
        end
    end
    
    // Output X pre-selection logic
    assign next_out_X = (sel_X == 2'b00) ? in_A_buf1 :
                        (sel_X == 2'b01) ? in_B :
                        (sel_X == 2'b10) ? in_D : h00_buf1;
    
    // Output Y pre-selection logic
    assign next_out_Y = (sel_Y == 2'b00) ? in_A_buf2 :
                        (sel_Y == 2'b01) ? in_B :
                        (sel_Y == 2'b10) ? in_C : h00_buf1;
    
    // Output Z pre-selection logic
    assign next_out_Z = (!sel_Z[0]) ? in_A_buf3 :
                        (!sel_Z[1]) ? in_C : h00_buf2;
    
    // Sequential logic for final outputs
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            out_X <= 8'h00;
            out_Y <= 8'h00;
            out_Z <= 8'h00;
        end else begin
            out_X <= next_out_X_buf2;
            out_Y <= next_out_Y_buf2;
            out_Z <= next_out_Z_buf2;
        end
    end
endmodule