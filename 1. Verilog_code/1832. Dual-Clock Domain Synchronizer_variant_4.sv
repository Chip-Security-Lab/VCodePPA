//SystemVerilog
// 顶层模块
module cross_domain_sync #(parameter BUS_WIDTH = 16) (
    // Source domain signals
    input  wire                  src_clk,
    input  wire                  src_rst,
    input  wire [BUS_WIDTH-1:0]  src_data,
    input  wire                  src_valid,
    output wire                  src_ready,
    
    // Destination domain signals
    input  wire                  dst_clk,
    input  wire                  dst_rst,
    output wire [BUS_WIDTH-1:0]  dst_data,
    output wire                  dst_valid,
    input  wire                  dst_ready
);
    // 内部连接信号
    wire src_toggle_flag;
    wire [2:0] dst_sync_flag;
    
    // 源域控制模块实例化
    source_controller #(
        .BUS_WIDTH(BUS_WIDTH)
    ) src_ctrl_inst (
        .clk(src_clk),
        .rst(src_rst),
        .src_valid(src_valid),
        .dst_sync_flag(dst_sync_flag[2]),
        .src_toggle_flag(src_toggle_flag),
        .src_ready(src_ready)
    );
    
    // 目标域同步模块实例化
    destination_controller #(
        .BUS_WIDTH(BUS_WIDTH)
    ) dst_ctrl_inst (
        .clk(dst_clk),
        .rst(dst_rst),
        .src_toggle_flag(src_toggle_flag),
        .src_data(src_data),
        .dst_ready(dst_ready),
        .dst_sync_flag(dst_sync_flag),
        .dst_data(dst_data),
        .dst_valid(dst_valid)
    );
    
endmodule

// 源域控制器子模块
module source_controller #(parameter BUS_WIDTH = 16) (
    input  wire clk,
    input  wire rst,
    input  wire src_valid,
    input  wire dst_sync_flag,
    output reg  src_toggle_flag,
    output reg  src_ready
);
    // 查找表辅助减法器 (3位)
    reg [2:0] diff;
    reg [7:0] lut_diff;
    
    // 减法器LUT初始化
    always @(*) begin
        case ({src_toggle_flag, dst_sync_flag})
            2'b00: diff = 3'b000;
            2'b01: diff = 3'b111; // -1 using 3-bit representation
            2'b10: diff = 3'b001; // +1
            2'b11: diff = 3'b000;
        endcase
    end
    
    // 源域状态控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            src_toggle_flag <= 1'b0;
            src_ready <= 1'b1;
        end else if (src_valid && src_ready) begin
            // 数据传输请求被接受，切换标志并等待确认
            src_toggle_flag <= ~src_toggle_flag;
            src_ready <= 1'b0;
        end else begin
            // 使用查找表辅助减法结果决定ready信号
            if (diff == 3'b000) begin
                src_ready <= 1'b1;
            end
        end
    end
endmodule

// 目标域控制器子模块
module destination_controller #(parameter BUS_WIDTH = 16) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  src_toggle_flag,
    input  wire [BUS_WIDTH-1:0]  src_data,
    input  wire                  dst_ready,
    output reg  [2:0]            dst_sync_flag,
    output reg  [BUS_WIDTH-1:0]  dst_data,
    output reg                   dst_valid
);
    // 查找表辅助状态比较
    reg [2:0] flag_diff;
    wire flag_changed;
    
    // LUT实现的标志比较
    always @(*) begin
        case ({dst_sync_flag[2], dst_sync_flag[1]})
            2'b00: flag_diff = 3'b000;
            2'b01: flag_diff = 3'b001;
            2'b10: flag_diff = 3'b111; // -1 using 3-bit representation
            2'b11: flag_diff = 3'b000;
        endcase
    end
    
    // 使用LUT输出确定标志是否变化
    assign flag_changed = (flag_diff != 3'b000);
    
    // 目标域同步和数据捕获逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dst_sync_flag <= 3'b000;
            dst_valid <= 1'b0;
            dst_data <= {BUS_WIDTH{1'b0}};
        end else begin
            // 同步器链，用于安全捕获源域切换标志
            dst_sync_flag <= {dst_sync_flag[1:0], src_toggle_flag};
            
            // 使用查找表辅助检测切换标志变化，表示有新数据
            if (flag_changed && !dst_valid) begin
                dst_data <= src_data;
                dst_valid <= 1'b1;
            end else if (dst_valid && dst_ready) begin
                // 数据已被消费，清除有效标志
                dst_valid <= 1'b0;
            end
        end
    end
endmodule