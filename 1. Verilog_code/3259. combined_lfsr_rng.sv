module combined_lfsr_rng (
    input wire clk,
    input wire n_rst,
    output wire [31:0] random_value
);
    reg [16:0] lfsr1;
    reg [18:0] lfsr2;
    wire feedback1, feedback2;
    
    assign feedback1 = lfsr1[16] ^ lfsr1[13];
    assign feedback2 = lfsr2[18] ^ lfsr2[17] ^ lfsr2[11] ^ lfsr2[0];
    
    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            lfsr1 <= 17'h1ACEF;
            lfsr2 <= 19'h5B4FC;
        end else begin
            lfsr1 <= {lfsr1[15:0], feedback1};
            lfsr2 <= {lfsr2[17:0], feedback2};
        end
    end
    
    assign random_value = {lfsr1[15:0], lfsr2[15:0]};
endmodule