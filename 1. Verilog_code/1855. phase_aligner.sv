module phase_aligner #(parameter PHASES=4, DATA_W=8) (
    input clk, rst,
    input [DATA_W-1:0] phase_data_0,
    input [DATA_W-1:0] phase_data_1,
    input [DATA_W-1:0] phase_data_2,
    input [DATA_W-1:0] phase_data_3,
    output reg [DATA_W-1:0] aligned_data
);
    reg [DATA_W-1:0] sync_reg [0:PHASES-1];
    integer i;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for(i=0; i<PHASES; i=i+1)
                sync_reg[i] <= 0;
        end else begin
            sync_reg[0] <= phase_data_1; // (0+1)%4 = 1
            sync_reg[1] <= phase_data_2; // (1+1)%4 = 2
            sync_reg[2] <= phase_data_3; // (2+1)%4 = 3
            sync_reg[3] <= phase_data_0; // (3+1)%4 = 0
        end
    end
    
    always @(posedge clk)
        aligned_data <= sync_reg[0] ^ sync_reg[1] ^ sync_reg[2] ^ sync_reg[3];
endmodule