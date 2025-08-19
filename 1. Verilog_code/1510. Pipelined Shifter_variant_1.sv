//SystemVerilog
module pipelined_shifter #(parameter STAGES = 4, WIDTH = 8) (
    input wire clk, rst_n,
    input wire valid_in,           // 输入数据有效信号
    input wire [WIDTH-1:0] data_in,
    output wire valid_out,         // 输出数据有效信号
    output wire [WIDTH-1:0] data_out,
    input wire flush               // 流水线刷新信号
);
    // 数据流水线寄存器
    reg [WIDTH-1:0] pipe_data [0:STAGES-1];
    // 有效信号流水线寄存器
    reg pipe_valid [0:STAGES-1];
    
    // 输入阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_data[0] <= {WIDTH{1'b0}};
            pipe_valid[0] <= 1'b0;
        end else if (flush) begin
            pipe_data[0] <= {WIDTH{1'b0}};
            pipe_valid[0] <= 1'b0;
        end else begin
            pipe_data[0] <= data_in;
            pipe_valid[0] <= valid_in;
        end
    end
    
    // 生成中间流水线阶段
    genvar j;
    generate
        for (j = 1; j < STAGES; j = j + 1) begin : pipe_stages
            // 处理每个管道阶段的数据和控制信号
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipe_data[j] <= {WIDTH{1'b0}};
                    pipe_valid[j] <= 1'b0;
                end else if (flush) begin
                    pipe_data[j] <= {WIDTH{1'b0}};
                    pipe_valid[j] <= 1'b0;
                end else begin
                    // 添加了移位操作，使每一级有计算功能，提高硬件利用率
                    case (j % 3)
                        0: pipe_data[j] <= pipe_data[j-1] >> 1;  // 右移
                        1: pipe_data[j] <= pipe_data[j-1] << 1;  // 左移
                        2: pipe_data[j] <= pipe_data[j-1];       // 保持
                    endcase
                    pipe_valid[j] <= pipe_valid[j-1];
                end
            end
        end
    endgenerate
    
    // 输出赋值
    assign data_out = pipe_data[STAGES-1];
    assign valid_out = pipe_valid[STAGES-1];
    
    // 性能监控计数器（记录流水线吞吐量）
    reg [31:0] throughput_counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            throughput_counter <= 32'h0;
        end else if (valid_out) begin
            throughput_counter <= throughput_counter + 1'b1;
        end
    end
    
endmodule