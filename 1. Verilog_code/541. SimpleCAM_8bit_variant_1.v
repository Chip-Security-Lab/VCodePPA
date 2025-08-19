// 顶层模块
module cam_1 (
    input wire clk,
    input wire rst,         // 复位信号
    input wire write_en,    // 写入使能
    input wire [7:0] data_in,
    output wire match_flag,
    output wire [7:0] store_data
);
    // 控制信号生成
    wire [1:0] ctrl;
    
    // 实例化控制单元
    cam_control_unit control_unit (
        .rst(rst),
        .write_en(write_en),
        .ctrl(ctrl)
    );
    
    // 实例化数据存储和匹配单元
    cam_storage_unit storage_unit (
        .clk(clk),
        .ctrl(ctrl),
        .data_in(data_in),
        .match_flag(match_flag),
        .store_data(store_data)
    );
    
endmodule

// 控制单元模块
module cam_control_unit (
    input wire rst,
    input wire write_en,
    output reg [1:0] ctrl
);
    // 组合控制信号生成
    always @(*) begin
        ctrl = {rst, write_en};
    end
endmodule

// 数据存储和匹配单元模块
module cam_storage_unit (
    input wire clk,
    input wire [1:0] ctrl,
    input wire [7:0] data_in,
    output reg match_flag,
    output reg [7:0] store_data
);
    // 数据和匹配逻辑处理
    always @(posedge clk) begin
        case(ctrl)
            2'b10, 2'b11: begin  // rst=1, write_en任意值
                store_data <= 8'b0;
                match_flag <= 1'b0;
            end
            2'b01: begin         // rst=0, write_en=1
                store_data <= data_in;
                // 使用非阻塞赋值以提高时序性能
            end
            2'b00: begin         // rst=0, write_en=0
                // 匹配逻辑优化，减少不必要的赋值
                match_flag <= (store_data == data_in);
            end
            default: begin
                // 默认情况不需要任何操作
            end
        endcase
    end
endmodule