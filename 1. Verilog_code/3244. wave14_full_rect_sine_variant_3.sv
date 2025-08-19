//SystemVerilog
module wave14_full_rect_sine #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    reg [ADDR_WIDTH-1:0] addr;
    wire signed [DATA_WIDTH-1:0] rom_value;
    
    // 使用函数替代ROM初始化
    function signed [DATA_WIDTH-1:0] get_rom_value;
        input [ADDR_WIDTH-1:0] addr;
        begin
            get_rom_value = addr - (1<<(DATA_WIDTH-1));
        end
    endfunction
    
    assign rom_value = get_rom_value(addr);
    
    always @(posedge clk) begin
        if(rst) begin
            addr <= 0;
        end
        else begin
            addr <= addr + 1;
        end
        
        // 将条件运算符转换为if-else结构
        if(rom_value < 0) begin
            wave_out <= -rom_value;
        end
        else begin
            wave_out <= rom_value;
        end
    end
endmodule