//SystemVerilog
module hybrid_reset_counter (
    input  wire        clk,       // 时钟信号
    input  wire        async_rst, // 异步复位
    input  wire        valid,     // 数据有效信号(由req更名)
    input  wire [3:0]  data_in,   // 输入数据
    output reg         ready,     // 准备接收信号(由ack更名)
    output reg  [3:0]  data_out   // 输出数据
);

    reg [3:0] next_data;
    reg processing;
    
    // 生成下一个状态的数据
    always @(*) begin
        if (processing)
            next_data = {data_out[0], data_out[3:1]};
        else
            next_data = data_out;
    end

    // Valid-Ready握手逻辑与数据处理
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            data_out <= 4'b1000;
            ready <= 1'b1;       // 复位后即准备好接收数据
            processing <= 1'b0;
        end
        else begin
            if (valid && ready) begin
                // 成功握手，接收新数据
                if (data_in == 4'b0000) begin
                    // 同步清除操作
                    data_out <= 4'b0001;
                end
                else begin
                    // 正常操作
                    data_out <= next_data;
                end
                processing <= 1'b1;
                ready <= 1'b0;    // 数据处理期间不接收新数据
            end
            else if (processing) begin
                // 数据处理阶段
                data_out <= next_data;
                processing <= 1'b0;
                ready <= 1'b1;    // 处理完成后准备接收新数据
            end
        end
    end

endmodule