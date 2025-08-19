//SystemVerilog
module PredictCompress #(
    parameter DATA_WIDTH = 16,
    parameter DELTA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,  // 新增复位信号
    input wire en,
    input wire [DATA_WIDTH-1:0] current,
    output wire [DELTA_WIDTH-1:0] delta
);
    // 内部连线
    wire [DATA_WIDTH-1:0] prev_value;
    wire valid_delta;
    
    // 子模块实例化
    DataStorage #(
        .DATA_WIDTH(DATA_WIDTH)
    ) history_unit (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_in(current),
        .data_out(prev_value)
    );
    
    DeltaComputation #(
        .DATA_WIDTH(DATA_WIDTH),
        .DELTA_WIDTH(DELTA_WIDTH)
    ) delta_unit (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .current_value(current),
        .previous_value(prev_value),
        .delta_out(delta),
        .valid(valid_delta)
    );
    
endmodule

// 数据存储子模块
module DataStorage #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    // 使用复位逻辑增强鲁棒性
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (en) begin
            data_out <= data_in;
        end
    end
endmodule

// 差值计算子模块
module DeltaComputation #(
    parameter DATA_WIDTH = 16,
    parameter DELTA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [DATA_WIDTH-1:0] current_value,
    input wire [DATA_WIDTH-1:0] previous_value,
    output reg [DELTA_WIDTH-1:0] delta_out,
    output reg valid
);
    // 中间寄存器用于优化时序路径
    reg [DATA_WIDTH-1:0] diff;
    
    // 差值计算逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= {DATA_WIDTH{1'b0}};
            delta_out <= {DELTA_WIDTH{1'b0}};
            valid <= 1'b0;
        end else if (en) begin
            // 计算差值并检查溢出
            diff <= current_value - previous_value;
            
            // 处理差值截断和饱和
            if (|diff[DATA_WIDTH-1:DELTA_WIDTH]) begin
                // 溢出处理 - 饱和到最大值
                delta_out <= {DELTA_WIDTH{1'b1}};
            end else begin
                // 正常情况 - 截断到DELTA_WIDTH位
                delta_out <= diff[DELTA_WIDTH-1:0];
            end
            
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule