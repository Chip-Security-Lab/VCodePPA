module galois_lfsr_rng (
    input wire clock,
    input wire reset,
    input wire enable,
    output reg [7:0] rand_data
);
    always @(posedge clock) begin
        if (reset)
            rand_data <= 8'h1;
        else if (enable) begin
            rand_data[0] <= rand_data[7];
            rand_data[1] <= rand_data[0];
            rand_data[2] <= rand_data[1] ^ rand_data[7];
            rand_data[3] <= rand_data[2] ^ rand_data[7];
            rand_data[4] <= rand_data[3];
            rand_data[5] <= rand_data[4] ^ rand_data[7];
            rand_data[6] <= rand_data[5];
            rand_data[7] <= rand_data[6];
        end
    end
endmodule
