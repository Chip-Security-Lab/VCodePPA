//SystemVerilog
module wave14_full_rect_sine #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    // Stage 1: Address generation
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg valid_stage1;
    
    // Stage 2: ROM lookup
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg signed [DATA_WIDTH-1:0] rom_value_stage2;
    reg valid_stage2;
    
    // Stage 3: Rectification
    reg signed [DATA_WIDTH-1:0] rom_value_stage3;
    reg valid_stage3;
    
    // 使用函数替代ROM初始化
    function signed [DATA_WIDTH-1:0] get_rom_value;
        input [ADDR_WIDTH-1:0] addr;
        begin
            get_rom_value = addr - (1<<(DATA_WIDTH-1));
        end
    endfunction
    
    // Stage 1: Address generation pipeline
    always @(posedge clk) begin
        if(rst) begin
            addr_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            addr_stage1 <= addr_stage1 + 1;
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2: ROM lookup pipeline
    always @(posedge clk) begin
        if(rst) begin
            addr_stage2 <= 0;
            rom_value_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            addr_stage2 <= addr_stage1;
            rom_value_stage2 <= get_rom_value(addr_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Rectification pipeline
    always @(posedge clk) begin
        if(rst) begin
            rom_value_stage3 <= 0;
            valid_stage3 <= 0;
        end
        else begin
            rom_value_stage3 <= rom_value_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if(rst) begin
            wave_out <= 0;
        end
        else if(valid_stage3) begin
            wave_out <= (rom_value_stage3 < 0) ? -rom_value_stage3 : rom_value_stage3;
        end
    end
endmodule