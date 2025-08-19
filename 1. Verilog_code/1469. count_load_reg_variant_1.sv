//SystemVerilog
module count_load_reg(
    input clk, rst,
    input [7:0] load_val,
    input req, // 替代原有的load信号，表示请求
    input count_req, // 替代原有的count_en信号，表示计数请求
    output reg ack, // 新增应答信号，表示已响应请求
    output reg count_ack, // 新增计数应答信号，表示已响应计数请求
    output [7:0] count
);
    // 使用中间信号以便在不同的always块中处理
    reg [7:0] count_r;
    reg [7:0] next_count;
    reg req_r, count_req_r; // 请求信号的寄存器版本
    
    // 输出赋值
    assign count = count_r;
    
    // 第一个always块：计算下一个计数值的组合逻辑
    always @(*) begin : next_count_logic
        if (req && !req_r)
            next_count = load_val;
        else if (count_req && !count_req_r)
            next_count = count_r + 1'b1;
        else
            next_count = count_r;
    end
    
    // 应答信号生成逻辑
    always @(posedge clk or posedge rst) begin : ack_generation
        if (rst) begin
            ack <= 1'b0;
            count_ack <= 1'b0;
            req_r <= 1'b0;
            count_req_r <= 1'b0;
        end
        else begin
            req_r <= req;
            count_req_r <= count_req;
            
            // 负载请求应答逻辑
            if (req && !req_r)
                ack <= 1'b1;
            else if (!req)
                ack <= 1'b0;
                
            // 计数请求应答逻辑
            if (count_req && !count_req_r)
                count_ack <= 1'b1;
            else if (!count_req)
                count_ack <= 1'b0;
        end
    end
    
    // 寄存器更新逻辑
    always @(posedge clk or posedge rst) begin : register_update
        if (rst)
            count_r <= 8'h00;
        else
            count_r <= next_count;
    end
    
endmodule