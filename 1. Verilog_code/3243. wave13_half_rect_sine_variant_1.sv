//SystemVerilog
module wave13_half_rect_sine #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    reg [ADDR_WIDTH-1:0] addr;
    reg signed [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    
    // Pipeline registers
    reg signed [DATA_WIDTH-1:0] rom_data_reg;
    reg rom_data_negative_reg;
    
    // 使用$signed确保正确处理有符号数
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) 
            rom[i] = $signed(i - (1<<(DATA_WIDTH-1)));
    end

    always @(posedge clk) begin
        if(rst) begin
            addr <= 0;
            rom_data_reg <= 0;
            rom_data_negative_reg <= 0;
            wave_out <= 0;
        end
        else begin
            addr <= addr + 1;
            
            // Pipeline stage 1: Load data from ROM
            rom_data_reg <= rom[addr];
            
            // Pipeline stage 2: Compute whether data is negative
            if($signed(rom_data_reg) < 0) begin
                rom_data_negative_reg <= 1'b1;
            end
            else begin
                rom_data_negative_reg <= 1'b0;
            end
            
            // Pipeline stage 3: Generate output
            if(rom_data_negative_reg) begin
                wave_out <= 0;
            end
            else begin
                wave_out <= rom_data_reg[DATA_WIDTH-1:0];
            end
        end
    end
endmodule