//SystemVerilog
module conditional_buffer (
    input  wire       clk,
    input  wire       rst_n,         // 复位信号
    input  wire [7:0] data_in,
    input  wire [7:0] threshold,
    input  wire       valid_in,      // 输入有效信号
    output reg        ready_in,      // 输入就绪信号
    output reg  [7:0] data_out,
    output reg        valid_out,     // 输出有效信号
    input  wire       ready_out      // 下游就绪信号
);

    // 内部寄存器
    reg [7:0] data_buffer;
    reg       data_valid;
    wire      can_accept_new;        // 判断是否可以接受新数据
    wire      threshold_check;       // 优化的比较逻辑

    // 优化比较逻辑 - 使用单一比较操作
    assign threshold_check = (data_in > threshold);
    
    // 标志是否可以接受新数据
    assign can_accept_new = !data_valid || (valid_out && ready_out);

    // 输入侧握手和数据缓存逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in    <= 1'b1;
            data_buffer <= 8'b0;
            data_valid  <= 1'b0;
        end 
        else begin
            // 默认逻辑 - 如果数据已被下游接收，则重新准备接收新数据
            if (data_valid && valid_out && ready_out) 
                data_valid <= 1'b0;

            // 输入有效且当前模块准备好接收
            if (valid_in && ready_in) begin
                if (threshold_check) begin
                    data_buffer <= data_in;
                    data_valid  <= 1'b1;
                end
            end
            
            // 更新ready_in信号
            ready_in <= !valid_in || !threshold_check || can_accept_new;
        end
    end

    // 输出侧握手逻辑 - 简化状态转换
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 8'b0;
            valid_out <= 1'b0;
        end 
        else begin
            if (data_valid && (!valid_out || ready_out)) begin
                data_out  <= data_buffer;
                valid_out <= 1'b1;
            end 
            else if (valid_out && ready_out && !data_valid) begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule