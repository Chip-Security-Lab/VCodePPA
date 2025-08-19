//SystemVerilog
//IEEE 1364-2005 Verilog标准
module lfsr_4bit (
    input wire clk,
    input wire rst_n,
    input wire ready,        // 新增：接收方准备好接收数据的信号
    output wire valid,       // 新增：数据有效信号
    output wire [3:0] pseudo_random
);
    reg [3:0] lfsr;
    wire feedback;
    reg data_valid;          // 控制数据有效性的寄存器
    
    assign feedback = lfsr[1] ^ lfsr[3];  // Polynomial: x^4 + x^2 + 1
    
    // 握手逻辑：只有当ready和valid都为高时才进行数据传输
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 4'b0001;
            data_valid <= 1'b0;
        end
        else begin
            data_valid <= 1'b1;  // 数据始终有效
            
            // 只有当接收方准备好(ready=1)且当前数据有效(valid=1)时才更新LFSR
            if (ready && data_valid) begin
                lfsr <= {lfsr[2:0], feedback};
            end
        end
    end
    
    assign valid = data_valid;
    assign pseudo_random = lfsr;
endmodule