module elias_gamma (
    input            enable,
    input     [15:0] value,
    output reg [31:0] code,
    output reg [5:0] length
);
    reg [4:0] N;
    integer i;
    reg [15:0] val_masked;
    
    always @(*) begin
        if (enable) begin
            // Find position of MSB using priority encoding
            N = 0;
            val_masked = value;
            
            if (val_masked[15:8] != 0) begin N = N + 8; val_masked = val_masked[15:8]; end else val_masked = val_masked[7:0];
            if (val_masked[7:4] != 0) begin N = N + 4; val_masked = val_masked[7:4]; end else val_masked = val_masked[3:0];
            if (val_masked[3:2] != 0) begin N = N + 2; val_masked = val_masked[3:2]; end else val_masked = val_masked[1:0];
            if (val_masked[1] != 0) begin N = N + 1; end
            
            // Add 1 for final position (N is now bit position, 0-based)
            N = N + 1;
            
            // Generate code
            code = 0;
            
            // N-1 zeros followed by a 1
            for (i = 0; i < 32; i = i + 1) begin
                if (i < N-1)
                    code[31-i] = 1'b0;
                else if (i == N-1)
                    code[31-i] = 1'b1;
                else if (i < 2*N-1)
                    code[31-i] = value[N-1-(i-N)];
            end
            
            length = 2*N - 1;
        end else begin
            code = 0;
            length = 0;
        end
    end
endmodule