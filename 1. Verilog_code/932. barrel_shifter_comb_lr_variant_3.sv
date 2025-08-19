//SystemVerilog
module barrel_shifter_valid_ready (
    input wire clk,
    input wire rst_n,
    
    // 数据输入
    input wire [15:0] din,
    input wire [3:0] shift,
    input wire valid_in,  // 发送方表示数据有效
    output wire ready_out, // 接收方表示准备接收
    
    // 数据输出
    output reg [15:0] dout,
    output reg valid_out,  // 发送方表示数据有效
    input wire ready_in    // 接收方表示准备接收
);

    // 内部状态和信号
    reg [15:0] din_reg;
    reg [3:0] shift_reg;
    reg busy;
    
    // 握手控制逻辑
    assign ready_out = !busy || (valid_out && ready_in);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg <= 16'b0;
            shift_reg <= 4'b0;
            busy <= 1'b0;
            valid_out <= 1'b0;
            dout <= 16'b0;
        end else begin
            // 数据接收逻辑
            if (valid_in && ready_out) begin
                din_reg <= din;
                shift_reg <= shift;
                busy <= 1'b1;
                // 直接计算并在下一个周期输出
                dout <= din >> shift;
                valid_out <= 1'b1;
            end
            
            // 数据发送完成逻辑
            if (valid_out && ready_in) begin
                valid_out <= 1'b0;
                busy <= 1'b0;
            end
        end
    end
    
endmodule