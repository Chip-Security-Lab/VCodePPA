//SystemVerilog
module separate_addr_regfile #(
    parameter DATA_W = 32,
    parameter WR_ADDR_W = 4,   // Write address width
    parameter RD_ADDR_W = 5    // Read address width (can address more locations)
)(
    input  wire                  clk,
    input  wire                  rst_n,
    
    // Write port (fewer addresses)
    input  wire                  wr_en,
    input  wire [WR_ADDR_W-1:0]  wr_addr,
    input  wire [DATA_W-1:0]     wr_data,
    
    // Read port (more addresses)
    input  wire [RD_ADDR_W-1:0]  rd_addr,
    output wire [DATA_W-1:0]     rd_data
);
    // Storage - sized by the larger address space
    reg [DATA_W-1:0] registers [0:(2**RD_ADDR_W)-1];
    
    // Implement 8-bit conditional sum subtractor
    wire [7:0] minuend;    // 被减数
    wire [7:0] subtrahend; // 减数
    wire [7:0] difference; // 差
    
    // Extract 8-bit operands from the data being written
    assign minuend = wr_data[7:0];
    assign subtrahend = wr_data[15:8];
    
    // Conditional sum subtractor implementation
    wire [7:0] subtrahend_complement;
    wire [7:0] sum0, sum1; // Sum assuming carry-in is 0 or 1
    wire [3:0] carry0, carry1; // Carries for each 2-bit group
    
    // One's complement of subtrahend
    assign subtrahend_complement = ~subtrahend;
    
    // First level - 2-bit groups
    // Group 0 (bits 0-1)
    assign sum0[1:0] = minuend[1:0] + subtrahend_complement[1:0] + 1'b1;
    assign carry0[0] = (minuend[1:0] + subtrahend_complement[1:0] + 1'b1) > 2'b11;
    
    // Group 1 (bits 2-3)
    assign sum0[3:2] = minuend[3:2] + subtrahend_complement[3:2] + 1'b0;
    assign sum1[3:2] = minuend[3:2] + subtrahend_complement[3:2] + 1'b1;
    assign carry0[1] = (minuend[3:2] + subtrahend_complement[3:2] + 1'b0) > 2'b11;
    assign carry1[1] = (minuend[3:2] + subtrahend_complement[3:2] + 1'b1) > 2'b11;
    
    // Group 2 (bits 4-5)
    assign sum0[5:4] = minuend[5:4] + subtrahend_complement[5:4] + 1'b0;
    assign sum1[5:4] = minuend[5:4] + subtrahend_complement[5:4] + 1'b1;
    assign carry0[2] = (minuend[5:4] + subtrahend_complement[5:4] + 1'b0) > 2'b11;
    assign carry1[2] = (minuend[5:4] + subtrahend_complement[5:4] + 1'b1) > 2'b11;
    
    // Group 3 (bits 6-7)
    assign sum0[7:6] = minuend[7:6] + subtrahend_complement[7:6] + 1'b0;
    assign sum1[7:6] = minuend[7:6] + subtrahend_complement[7:6] + 1'b1;
    assign carry0[3] = (minuend[7:6] + subtrahend_complement[7:6] + 1'b0) > 2'b11;
    assign carry1[3] = (minuend[7:6] + subtrahend_complement[7:6] + 1'b1) > 2'b11;
    
    // Second level - select based on carries
    wire [7:2] final_sum;
    
    // Select bits 2-3 based on carry from bits 0-1
    assign final_sum[3:2] = carry0[0] ? sum1[3:2] : sum0[3:2];
    
    // Select bits 4-5 based on carry from bits 2-3
    wire carry_to_group2 = carry0[0] ? carry1[1] : carry0[1];
    assign final_sum[5:4] = carry_to_group2 ? sum1[5:4] : sum0[5:4];
    
    // Select bits 6-7 based on carry from bits 4-5
    wire carry_to_group3 = carry_to_group2 ? carry1[2] : carry0[2];
    assign final_sum[7:6] = carry_to_group3 ? sum1[7:6] : sum0[7:6];
    
    // Final result
    assign difference = {final_sum[7:2], sum0[1:0]};
    
    // Asynchronous read with subtractor result incorporated
    assign rd_data = (rd_addr == {(RD_ADDR_W){1'b0}}) ? 
                      {{(DATA_W-8){1'b0}}, difference} : registers[rd_addr];
    
    // Write operation (note that wr_addr only covers a subset of the registers)
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < (2**RD_ADDR_W); i = i + 1) begin
                registers[i] <= {DATA_W{1'b0}};
            end
        end
        else if (wr_en) begin
            // Write address is extended to match the full register address space
            if (wr_addr == {(WR_ADDR_W){1'b0}}) begin
                // When writing to address 0, store the difference result
                registers[{{(RD_ADDR_W-WR_ADDR_W){1'b0}}, wr_addr}] <= {{(DATA_W-8){1'b0}}, difference};
            end else begin
                registers[{{(RD_ADDR_W-WR_ADDR_W){1'b0}}, wr_addr}] <= wr_data;
            end
        end
    end
endmodule