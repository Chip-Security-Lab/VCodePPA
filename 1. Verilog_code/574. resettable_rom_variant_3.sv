//SystemVerilog
// 顶层模块
module resettable_rom (
    input clk,
    input rst,
    input [3:0] addr,
    output [7:0] data
);
    // 内部连线
    wire [7:0] rom_data;
    
    // ROM存储子模块
    rom_storage rom_inst (
        .addr(addr),
        .data(rom_data)
    );
    
    // 输出寄存器子模块
    output_register output_reg_inst (
        .clk(clk),
        .rst(rst),
        .data_in(rom_data),
        .data_out(data)
    );
endmodule

// ROM存储子模块
module rom_storage (
    input [3:0] addr,
    output [7:0] data
);
    // 参数化ROM大小
    parameter ROM_DEPTH = 16;
    parameter ROM_WIDTH = 8;
    
    // ROM存储器
    reg [ROM_WIDTH-1:0] mem [0:ROM_DEPTH-1];
    
    // ROM初始化
    initial begin
        mem[0] = 8'h12; mem[1] = 8'h34; mem[2] = 8'h56; mem[3] = 8'h78;
        mem[4] = 8'h9A; mem[5] = 8'hBC; mem[6] = 8'hDE; mem[7] = 8'hF0;
        mem[8] = 8'h00; mem[9] = 8'h00; mem[10] = 8'h00; mem[11] = 8'h00;
        mem[12] = 8'h00; mem[13] = 8'h00; mem[14] = 8'h00; mem[15] = 8'h00;
    end
    
    // 组合逻辑读取，降低延迟
    assign data = mem[addr];
endmodule

// 输出寄存器子模块
module output_register (
    input clk,
    input rst,
    input [7:0] data_in,
    output reg [7:0] data_out
);
    // 可配置的默认复位值
    parameter RESET_VALUE = 8'h00;
    
    // 寄存器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_out <= RESET_VALUE;  // 复位时输出默认值
        else
            data_out <= data_in;
    end
endmodule