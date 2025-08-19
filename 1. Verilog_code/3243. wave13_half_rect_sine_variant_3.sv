//SystemVerilog
module wave13_half_rect_sine #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    // 内部信号定义
    reg [ADDR_WIDTH-1:0] addr;
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg signed [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    reg signed [DATA_WIDTH-1:0] rom_data_stage1;
    reg signed [DATA_WIDTH-1:0] rom_data_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;

    // ROM初始化 - 生成正弦波数据
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) 
            rom[i] = $signed(i - (1<<(DATA_WIDTH-1)));
    end

    // 流水线阶段1: 地址计数器控制 - 负责地址生成
    always @(posedge clk) begin
        if(rst) begin
            addr <= {ADDR_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin    
            addr <= addr + 1'b1;
            valid_stage1 <= 1'b1;
        end
    end

    // 流水线阶段2: ROM读取逻辑 - 获取ROM数据
    always @(posedge clk) begin
        if(rst) begin
            rom_data_stage1 <= {DATA_WIDTH{1'b0}};
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            rom_data_stage1 <= rom[addr];
            addr_stage1 <= addr;
            valid_stage2 <= valid_stage1;
        end
    end

    // 流水线阶段3: 波形整形逻辑 - 实现半波整流
    always @(posedge clk) begin
        if(rst) begin
            rom_data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end
        else begin
            rom_data_stage2 <= rom_data_stage1;
            valid_stage3 <= valid_stage2;
        end
    end

    // 流水线阶段4: 输出整形
    always @(posedge clk) begin
        if(rst) begin
            wave_out <= {DATA_WIDTH{1'b0}};
        end
        else if(valid_stage3) begin
            wave_out <= ($signed(rom_data_stage2) < 0) ? {DATA_WIDTH{1'b0}} : rom_data_stage2[DATA_WIDTH-1:0];
        end
    end

endmodule