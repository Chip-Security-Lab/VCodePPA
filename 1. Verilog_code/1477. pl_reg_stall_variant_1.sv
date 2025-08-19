//SystemVerilog
module pl_reg_stall #(parameter W=4) (
    input clk, rst, load, stall,
    input [W-1:0] new_data,
    output reg [W-1:0] current_data
);
    // 引入中间数据路径变量
    reg load_reg;
    reg stall_reg;
    reg [W-1:0] new_data_reg;
    
    // 将输入信号寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            load_reg <= 0;
            stall_reg <= 0;
            new_data_reg <= 0;
        end else begin
            load_reg <= load;
            stall_reg <= stall;
            new_data_reg <= new_data;
        end
    end
    
    // 主逻辑处理部分 - 使用已寄存的输入信号并采用case结构
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_data <= 0;
        end else begin
            case ({stall_reg, load_reg})
                2'b00: current_data <= current_data; // 不stall且不load，保持原值
                2'b01: current_data <= new_data_reg; // 不stall且load，加载新数据
                2'b10: current_data <= current_data; // stall，保持原值
                2'b11: current_data <= current_data; // stall且load，保持原值(stall优先)
            endcase
        end
    end
endmodule