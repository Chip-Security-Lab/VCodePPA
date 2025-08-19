//SystemVerilog
module parity_regfile #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output wire [DATA_WIDTH-1:0]  rd_data,
    output wire                   parity_error
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DEPTH-1:0] parity;
    
    // Optimized parity calculation using parallel XOR tree
    function automatic bit calc_parity;
        input [DATA_WIDTH-1:0] data;
        reg [DATA_WIDTH/2-1:0] xor_stage1;
        reg [DATA_WIDTH/4-1:0] xor_stage2;
        reg [DATA_WIDTH/8-1:0] xor_stage3;
        begin
            // First stage: parallel XOR
            for (int i = 0; i < DATA_WIDTH/2; i = i + 1)
                xor_stage1[i] = data[2*i] ^ data[2*i+1];
            
            // Second stage: parallel XOR
            for (int i = 0; i < DATA_WIDTH/4; i = i + 1)
                xor_stage2[i] = xor_stage1[2*i] ^ xor_stage1[2*i+1];
            
            // Third stage: parallel XOR
            for (int i = 0; i < DATA_WIDTH/8; i = i + 1)
                xor_stage3[i] = xor_stage2[2*i] ^ xor_stage2[2*i+1];
            
            // Final reduction
            calc_parity = ^xor_stage3;
        end
    endfunction
    
    // Optimized write operation with parallel reset
    always @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= '0;
                parity[i] <= 1'b0;
            end
        end else if (wr_en) begin
            mem[wr_addr] <= wr_data;
            parity[wr_addr] <= calc_parity(wr_data);
        end
    end
    
    // Registered read operation for better timing
    reg [DATA_WIDTH-1:0] rd_data_reg;
    reg parity_error_reg;
    
    always @(posedge clk) begin
        rd_data_reg <= mem[rd_addr];
        parity_error_reg <= (calc_parity(mem[rd_addr]) != parity[rd_addr]);
    end
    
    assign rd_data = rd_data_reg;
    assign parity_error = parity_error_reg;
    
endmodule