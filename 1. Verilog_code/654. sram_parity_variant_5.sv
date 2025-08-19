//SystemVerilog
module sram_parity #(
    parameter DATA_BITS = 8
)(
    input clk,
    input rst_n,
    input we,
    input [3:0] addr,
    input [DATA_BITS-1:0] din,
    output reg [DATA_BITS:0] dout,
    output reg valid
);

    localparam TOTAL_BITS = DATA_BITS + 1;
    localparam STAGES = 4;
    
    // Memory array
    reg [TOTAL_BITS-1:0] mem [0:15];
    
    // Pipeline registers
    reg [3:0] addr_stage1, addr_stage2, addr_stage3, addr_stage4;
    reg [DATA_BITS-1:0] din_stage1, din_stage2, din_stage3, din_stage4;
    reg we_stage1, we_stage2, we_stage3, we_stage4;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Carry-save adder pipeline registers
    reg [3:0] carry_stage1, carry_stage2, carry_stage3;
    reg [3:0] sum_stage1, sum_stage2, sum_stage3;
    reg parity_stage4;
    
    // Stage 1: Input sampling and first level calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            din_stage1 <= 0;
            we_stage1 <= 0;
            valid_stage1 <= 0;
            carry_stage1 <= 0;
            sum_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            din_stage1 <= din;
            we_stage1 <= we;
            valid_stage1 <= 1;
            sum_stage1[0] <= din[0] ^ din[1];
            carry_stage1[0] <= din[0] & din[1];
            sum_stage1[1] <= din[2] ^ din[3];
            carry_stage1[1] <= din[2] & din[3];
        end
    end
    
    // Stage 2: Second level calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 0;
            din_stage2 <= 0;
            we_stage2 <= 0;
            valid_stage2 <= 0;
            carry_stage2 <= 0;
            sum_stage2 <= 0;
        end else begin
            addr_stage2 <= addr_stage1;
            din_stage2 <= din_stage1;
            we_stage2 <= we_stage1;
            valid_stage2 <= valid_stage1;
            sum_stage2[0] <= sum_stage1[0] ^ sum_stage1[1];
            carry_stage2[0] <= sum_stage1[0] & sum_stage1[1];
            sum_stage2[1] <= carry_stage1[0] ^ carry_stage1[1];
            carry_stage2[1] <= carry_stage1[0] & carry_stage1[1];
        end
    end
    
    // Stage 3: Third level calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage3 <= 0;
            din_stage3 <= 0;
            we_stage3 <= 0;
            valid_stage3 <= 0;
            carry_stage3 <= 0;
            sum_stage3 <= 0;
        end else begin
            addr_stage3 <= addr_stage2;
            din_stage3 <= din_stage2;
            we_stage3 <= we_stage2;
            valid_stage3 <= valid_stage2;
            sum_stage3[0] <= sum_stage2[0] ^ carry_stage2[1];
            carry_stage3[0] <= sum_stage2[0] & carry_stage2[1];
        end
    end
    
    // Stage 4: Final parity calculation and memory write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage4 <= 0;
            din_stage4 <= 0;
            we_stage4 <= 0;
            valid_stage4 <= 0;
            parity_stage4 <= 0;
            dout <= 0;
            valid <= 0;
        end else begin
            addr_stage4 <= addr_stage3;
            din_stage4 <= din_stage3;
            we_stage4 <= we_stage3;
            valid_stage4 <= valid_stage3;
            parity_stage4 <= sum_stage3[0] ^ carry_stage3[0];
            
            if (we_stage4) begin
                mem[addr_stage4] <= {parity_stage4, din_stage4};
            end
            
            dout <= mem[addr_stage4];
            valid <= valid_stage4;
        end
    end
endmodule