//SystemVerilog
module XORChain (
    input wire clk,
    input wire rst_n,
    
    // Input interface with valid-ready handshake
    input wire [7:0] din,
    input wire valid_in,
    output reg ready_in,
    
    // Output interface with valid-ready handshake
    output reg [7:0] dout,
    output reg valid_out,
    input wire ready_out
);
    // 存储前一个输入值的寄存器
    reg [7:0] prev;
    reg [7:0] next_dout;
    reg data_valid;
    
    // 输入握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b1;
            prev <= 8'b0;
            data_valid <= 1'b0;
        end else begin
            if (valid_in && ready_in) begin
                // 接收到新数据
                prev <= din;
                data_valid <= 1'b1;
                // 如果输出通道被阻塞，暂停接收
                ready_in <= ready_out;
            end else if (valid_out && ready_out) begin
                // 数据已被接收，可以继续处理新数据
                data_valid <= 1'b0;
                ready_in <= 1'b1;
            end
        end
    end
    
    // 数据处理逻辑 - 计算XOR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_dout <= 8'b0;
        end else if (valid_in && ready_in) begin
            next_dout <= prev ^ din;
        end
    end
    
    // 输出握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            if (data_valid && ready_out) begin
                // 输出数据并置valid高
                dout <= next_dout;
                valid_out <= 1'b1;
            end else if (valid_out && ready_out) begin
                // 接收方已接收数据，清除valid信号
                valid_out <= 1'b0;
            end
        end
    end
endmodule