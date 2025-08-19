//SystemVerilog
module sync_low_rst_counter #(parameter COUNT_WIDTH=8)(
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire [COUNT_WIDTH-1:0] load_value,
    output reg [COUNT_WIDTH-1:0] counter
);
    // 提取控制信号作为case表达式
    reg [1:0] ctrl;
    
    always @(*) begin
        ctrl = {rst_n, load}; // 组合rst_n和load作为控制信号
    end
    
    // 使用case语句替代if-else级联结构
    always @(posedge clk) begin
        case(ctrl)
            2'b00: counter <= {COUNT_WIDTH{1'b0}}; // !rst_n
            2'b01: counter <= {COUNT_WIDTH{1'b0}}; // !rst_n (不考虑load)
            2'b10: counter <= counter + 1'b1;      // rst_n && !load
            2'b11: counter <= load_value;          // rst_n && load
        endcase
    end
endmodule