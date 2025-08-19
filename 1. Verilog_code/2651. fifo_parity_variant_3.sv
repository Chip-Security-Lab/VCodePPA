//SystemVerilog
module fifo_parity #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input clk, wr_en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH:0] fifo [0:DEPTH-1]
);
    // Pre-compute parity bit for data_in to reduce critical path
    reg parity_bit_stage1, parity_bit;
    reg [WIDTH-1:0] data_in_reg, data_in_reg2;
    reg wr_en_reg, wr_en_reg2;
    
    // First pipeline stage - register inputs and start parity calculation
    always @(posedge clk) begin
        data_in_reg <= data_in;
        wr_en_reg <= wr_en;
        // Split parity calculation into two stages for better timing
        parity_bit_stage1 <= ^data_in[WIDTH-1:WIDTH/2];
    end
    
    // Second pipeline stage - complete parity calculation
    always @(posedge clk) begin
        data_in_reg2 <= data_in_reg;
        wr_en_reg2 <= wr_en_reg;
        // Complete parity calculation by combining first half result with second half
        parity_bit <= parity_bit_stage1 ^ (^data_in_reg[WIDTH/2-1:0]);
    end
    
    // FIFO shift register with pipelined input
    integer i;
    always @(posedge clk) begin
        if (wr_en_reg2) begin
            fifo[0] <= {parity_bit, data_in_reg2};
            
            // Use for loops instead of while loops for better synthesis
            for (i = 1; i < DEPTH/2; i = i + 1) begin
                fifo[i] <= fifo[i-1];
            end
            
            for (i = DEPTH/2; i < DEPTH; i = i + 1) begin
                fifo[i] <= fifo[i-1];
            end
        end
    end
endmodule