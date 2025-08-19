//SystemVerilog
module decoder_arbiter #(NUM_MASTERS=2) (
    input [NUM_MASTERS-1:0] req,
    output reg [NUM_MASTERS-1:0] grant
);
    reg [NUM_MASTERS-1:0] req_inv;
    reg [NUM_MASTERS-1:0] sum;
    reg [NUM_MASTERS-1:0] carry;
    reg [NUM_MASTERS-1:0] result;
    reg [NUM_MASTERS-1:0] g;
    reg [NUM_MASTERS-1:0] p;
    
    // Request inversion
    always @* begin
        req_inv = ~req;
    end
    
    // Generate and propagate signals
    always @* begin
        for (integer i = 0; i < NUM_MASTERS; i = i + 1) begin
            g[i] = req_inv[i];
            p[i] = 1'b1;
        end
    end
    
    // Carry lookahead computation
    always @* begin
        carry[0] = 1'b1;
        for (integer i = 1; i < NUM_MASTERS; i = i + 1) begin
            carry[i] = g[i-1] | (p[i-1] & carry[i-1]);
        end
    end
    
    // Sum computation
    always @* begin
        for (integer i = 0; i < NUM_MASTERS; i = i + 1) begin
            sum[i] = req_inv[i] ^ carry[i];
        end
    end
    
    // Result calculation
    always @* begin
        result = sum;
    end
    
    // Final grant calculation
    always @* begin
        grant = req & result;
    end
endmodule