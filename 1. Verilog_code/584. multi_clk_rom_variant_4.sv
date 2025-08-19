//SystemVerilog
module multi_clk_rom (
    input clk_a, clk_b,
    input [3:0] addr_a,
    input [3:0] addr_b,
    output reg [7:0] data_a,
    output reg [7:0] data_b
);

    // ROM memory array
    reg [7:0] rom [0:15];
    
    // Pipeline registers for clock domain A
    reg [3:0] addr_a_stage1;
    reg [7:0] data_a_stage1;
    reg [7:0] data_a_stage2;
    reg valid_a_stage1;
    reg valid_a_stage2;
    
    // Pipeline registers for clock domain B  
    reg [3:0] addr_b_stage1;
    reg [7:0] data_b_stage1;
    reg [7:0] data_b_stage2;
    reg valid_b_stage1;
    reg valid_b_stage2;

    // ROM initialization
    initial begin
        rom[0] = 8'h11; rom[1] = 8'h22; rom[2] = 8'h33; rom[3] = 8'h44;
        rom[4] = 8'h55; rom[5] = 8'h66; rom[6] = 8'h77; rom[7] = 8'h88;
        rom[8] = 8'h99; rom[9] = 8'haa; rom[10] = 8'hbb; rom[11] = 8'hcc;
        rom[12] = 8'hdd; rom[13] = 8'hee; rom[14] = 8'hff; rom[15] = 8'h00;
    end

    // Clock domain A pipeline
    always @(posedge clk_a) begin
        // Stage 1: Address registration
        addr_a_stage1 <= addr_a;
        valid_a_stage1 <= 1'b1;
        
        // Stage 2: ROM access
        if (valid_a_stage1) begin
            data_a_stage1 <= rom[addr_a_stage1];
            valid_a_stage2 <= 1'b1;
        end else begin
            valid_a_stage2 <= 1'b0;
        end
        
        // Stage 3: Output registration
        if (valid_a_stage2) begin
            data_a_stage2 <= data_a_stage1;
            data_a <= data_a_stage2;
        end
    end

    // Clock domain B pipeline
    always @(posedge clk_b) begin
        // Stage 1: Address registration
        addr_b_stage1 <= addr_b;
        valid_b_stage1 <= 1'b1;
        
        // Stage 2: ROM access
        if (valid_b_stage1) begin
            data_b_stage1 <= rom[addr_b_stage1];
            valid_b_stage2 <= 1'b1;
        end else begin
            valid_b_stage2 <= 1'b0;
        end
        
        // Stage 3: Output registration
        if (valid_b_stage2) begin
            data_b_stage2 <= data_b_stage1;
            data_b <= data_b_stage2;
        end
    end

endmodule