//SystemVerilog
module programmable_rom (
    input clk,
    input rst_n,
    input prog_en,
    input [3:0] addr,
    input [7:0] din,
    output reg [7:0] data,
    output reg valid
);

    reg [7:0] rom [0:15];
    reg [15:0] programmed;
    
    // Pipeline stage 1 registers
    reg [3:0] addr_stage1;
    reg [7:0] din_stage1;
    reg prog_en_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] data_stage2;
    reg valid_stage2;
    
    // Stage 1: Address and control signal registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'b0;
            din_stage1 <= 8'b0;
            prog_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            din_stage1 <= din;
            prog_en_stage1 <= prog_en;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: ROM access and programming
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (prog_en_stage1 && ~programmed[addr_stage1]) begin
                rom[addr_stage1] <= din_stage1;
                programmed[addr_stage1] <= 1'b1;
            end
            data_stage2 <= rom[addr_stage1];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'b0;
            valid <= 1'b0;
        end else begin
            data <= data_stage2;
            valid <= valid_stage2;
        end
    end
    
    // Initialization
    initial begin
        programmed = 16'b0;
    end
endmodule