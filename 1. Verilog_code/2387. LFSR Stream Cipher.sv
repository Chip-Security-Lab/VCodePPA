module lfsr_stream_cipher #(parameter LFSR_WIDTH = 16, DATA_WIDTH = 8) (
    input wire clk, arst_l,
    input wire seed_load, encrypt,
    input wire [LFSR_WIDTH-1:0] seed,
    input wire [DATA_WIDTH-1:0] data_i,
    output reg [DATA_WIDTH-1:0] data_o
);
    reg [LFSR_WIDTH-1:0] lfsr_reg;
    wire feedback;
    
    assign feedback = lfsr_reg[0] ^ lfsr_reg[2] ^ lfsr_reg[3] ^ lfsr_reg[5]; // Tap positions
    
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) lfsr_reg <= {LFSR_WIDTH{1'b1}};
        else if (seed_load) lfsr_reg <= seed;
        else lfsr_reg <= {feedback, lfsr_reg[LFSR_WIDTH-1:1]};
    end
    
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) data_o <= 0;
        else if (encrypt) data_o <= data_i ^ lfsr_reg[LFSR_WIDTH-1:LFSR_WIDTH-DATA_WIDTH];
    end
endmodule