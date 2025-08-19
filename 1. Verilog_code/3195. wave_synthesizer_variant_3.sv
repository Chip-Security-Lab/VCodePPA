//SystemVerilog
// 顶层模块：流水线波形合成器
module wave_synthesizer #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    output wire valid_out,
    output wire [DATA_WIDTH-1:0] wave
);
    // 流水线阶段信号
    wire [ADDR_WIDTH-1:0] addr;
    wire addr_valid;
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg addr_valid_stage1;
    wire [DATA_WIDTH-1:0] wave_data;
    
    // 实例化地址生成器子模块
    addr_generator #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) addr_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .addr(addr),
        .addr_valid(addr_valid)
    );
    
    // 流水线寄存器 - 阶段1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
            addr_valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            addr_valid_stage1 <= addr_valid;
        end
    end
    
    // 实例化波形存储器子模块
    wave_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) wave_mem_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr_stage1),
        .addr_valid(addr_valid_stage1),
        .wave_data(wave_data),
        .wave_valid(valid_out)
    );
    
    // 输出赋值
    assign wave = wave_data;
    
endmodule

// 地址生成器子模块
module addr_generator #(
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [ADDR_WIDTH-1:0] addr,
    output reg addr_valid
);
    // 地址计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr <= {ADDR_WIDTH{1'b0}};
            addr_valid <= 1'b0;
        end else if (enable) begin
            addr <= addr + 1'b1;
            addr_valid <= 1'b1;
        end else begin
            addr_valid <= 1'b0;
        end
    end
    
endmodule

// 波形存储器子模块
module wave_memory #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire addr_valid,
    output reg [DATA_WIDTH-1:0] wave_data,
    output reg wave_valid
);
    // 波形查找表存储器
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] sine_rom [0:2**ADDR_WIDTH-1];
    
    // 中间流水线级寄存器
    reg [DATA_WIDTH-1:0] rom_data;
    reg rom_data_valid;
    
    // 初始化ROM内容
    initial $readmemh("sine_table.hex", sine_rom);
    
    // 流水线阶段1: ROM访问
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data <= {DATA_WIDTH{1'b0}};
            rom_data_valid <= 1'b0;
        end else begin
            rom_data <= sine_rom[addr];
            rom_data_valid <= addr_valid;
        end
    end
    
    // 流水线阶段2: 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wave_data <= {DATA_WIDTH{1'b0}};
            wave_valid <= 1'b0;
        end else begin
            wave_data <= rom_data;
            wave_valid <= rom_data_valid;
        end
    end
    
endmodule