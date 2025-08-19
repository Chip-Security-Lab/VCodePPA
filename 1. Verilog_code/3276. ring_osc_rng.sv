module ring_osc_rng (
    input wire system_clk,
    input wire reset_n,
    output reg [7:0] random_byte
);
    // Simulating multiple oscillators with different "frequencies"
    reg [3:0] osc_counters [3:0];
    wire [3:0] osc_bits;
    
    integer i;
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 4; i = i + 1)
                osc_counters[i] <= i + 1;
        end else begin
            for (i = 0; i < 4; i = i + 1)
                osc_counters[i] <= osc_counters[i] + (i + 1);
        end
    end
    
    // Derive oscillator outputs
    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin : osc_gen
            assign osc_bits[j] = osc_counters[j][3];
        end
    endgenerate
    
    // Collect random bits
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            random_byte <= 8'h42;
        else
            random_byte <= {random_byte[3:0], osc_bits};
    end
endmodule