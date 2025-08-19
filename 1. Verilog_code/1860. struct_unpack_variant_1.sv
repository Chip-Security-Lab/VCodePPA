//SystemVerilog
module struct_unpack #(
    parameter TOTAL_W = 32,
    parameter FIELD_N = 4
)(
    input wire                         clk,        // 时钟信号
    input wire                         rst_n,      // 复位信号
    input wire [TOTAL_W-1:0]           packed_data,
    input wire [$clog2(FIELD_N)-1:0]   select,
    output reg [TOTAL_W/FIELD_N-1:0]   unpacked
);
    // 参数定义
    localparam FIELD_W = TOTAL_W / FIELD_N;
    
    // 中间寄存器定义
    reg [TOTAL_W-1:0]          packed_data_reg;
    reg [$clog2(FIELD_N)-1:0]  select_reg;
    reg [TOTAL_W/FIELD_N-1:0]  field_values[0:FIELD_N-1];
    reg [TOTAL_W/FIELD_N-1:0]  selected_value;
    
    // 第一级流水线: 寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packed_data_reg <= {TOTAL_W{1'b0}};
            select_reg <= {$clog2(FIELD_N){1'b0}};
        end else begin
            packed_data_reg <= packed_data;
            select_reg <= select;
        end
    end
    
    // 第二级流水线: 解析各字段
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < FIELD_N; i = i + 1) begin
                field_values[i] <= {FIELD_W{1'b0}};
            end
        end else begin
            for (i = 0; i < FIELD_N; i = i + 1) begin
                field_values[i] <= packed_data_reg[i*FIELD_W +: FIELD_W];
            end
        end
    end
    
    // 第三级流水线: 字段选择
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_value <= {FIELD_W{1'b0}};
        end else begin
            selected_value <= field_values[select_reg];
        end
    end
    
    // 第四级流水线: 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unpacked <= {FIELD_W{1'b0}};
        end else begin
            unpacked <= selected_value;
        end
    end
    
endmodule