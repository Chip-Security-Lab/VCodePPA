//SystemVerilog
module file_rom (
    input clk,
    input rst_n,
    input valid_in,
    input [3:0] addr,
    output reg valid_out,
    output reg [7:0] data
);
    // ROM Memory
    reg [7:0] rom [0:15];
    
    // Stage 1 registers
    reg [3:0] addr_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [7:0] data_stage2;
    reg valid_stage2;
    
    initial begin
        $readmemh("rom_data.hex", rom); // 从文件加载数据
    end
    
    // Stage 1: Address Capture & ROM Read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Data Capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= rom[addr_stage1];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            data <= data_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule