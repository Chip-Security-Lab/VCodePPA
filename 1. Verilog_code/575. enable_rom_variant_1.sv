//SystemVerilog
module enable_rom (
    input wire clk,
    input wire en,
    input wire [3:0] addr,
    output wire [7:0] data
);
    // 内部连线
    wire [7:0] rom_data;
    wire rom_read;
    
    // ROM存储模块实例
    rom_storage rom_inst (
        .addr(addr),
        .data(rom_data)
    );
    
    // 控制逻辑模块实例
    rom_controller ctrl_inst (
        .clk(clk),
        .en(en),
        .rom_data(rom_data),
        .rom_read(rom_read),
        .data_out(data)
    );
endmodule

module rom_storage (
    input wire [3:0] addr,
    output reg [7:0] data
);
    // 参数化ROM内容
    parameter [7:0] ROM_CONTENT_0 = 8'h12;
    parameter [7:0] ROM_CONTENT_1 = 8'h34;
    parameter [7:0] ROM_CONTENT_2 = 8'h56;
    parameter [7:0] ROM_CONTENT_3 = 8'h78;
    parameter [7:0] ROM_CONTENT_4 = 8'h9A;
    parameter [7:0] ROM_CONTENT_5 = 8'hBC;
    parameter [7:0] ROM_CONTENT_6 = 8'hDE;
    parameter [7:0] ROM_CONTENT_7 = 8'hF0;
    
    // 只读访问ROM内容
    always @(*) begin
        case(addr)
            4'd0: data = ROM_CONTENT_0;
            4'd1: data = ROM_CONTENT_1;
            4'd2: data = ROM_CONTENT_2;
            4'd3: data = ROM_CONTENT_3;
            4'd4: data = ROM_CONTENT_4;
            4'd5: data = ROM_CONTENT_5;
            4'd6: data = ROM_CONTENT_6;
            4'd7: data = ROM_CONTENT_7;
            default: data = 8'h00;  // 未定义地址返回0
        endcase
    end
endmodule

module rom_controller (
    input wire clk,
    input wire en,
    input wire [7:0] rom_data,
    output wire rom_read,
    output reg [7:0] data_out
);
    // 启用信号与时钟同步
    reg en_reg;
    
    // 生成ROM读取信号
    assign rom_read = en;
    
    // 使能时输出ROM数据
    always @(posedge clk) begin
        if (en) 
            data_out <= rom_data;
    end
endmodule