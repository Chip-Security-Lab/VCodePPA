//SystemVerilog
module saturating_shifter (
    input [7:0] din,
    input [2:0] shift,
    output reg [7:0] dout
);
    wire [7:0] shifted_result;
    wire overflow_detected;
    
    // 计算移位结果
    assign shifted_result = din << shift;
    
    // 检测是否会溢出（当shift>5时，或者移位后高位有1时）
    assign overflow_detected = (shift > 3'd5) || (din[7:3] != 0 && shift > 0) || 
                               (din[7:4] != 0 && shift > 1) || 
                               (din[7:5] != 0 && shift > 2) ||
                               (din[7:6] != 0 && shift > 3) ||
                               (din[7] != 0 && shift > 4);
    
    // 输出逻辑
    always @* begin
        dout = overflow_detected ? 8'hFF : shifted_result;
    end
endmodule