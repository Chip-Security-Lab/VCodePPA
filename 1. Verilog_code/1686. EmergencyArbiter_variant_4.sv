//SystemVerilog
module EmergencyArbiter (
    input clk,
    input rst,
    input [3:0] req,
    input emergency,
    output reg [3:0] grant,
    output reg ack
);

    // 流水线寄存器
    reg [3:0] req_reg;
    reg emergency_reg;
    reg req_valid;
    
    // 中间信号
    wire [3:0] normal_grant;
    wire [3:0] final_grant;
    
    // 请求寄存器级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            req_reg <= 4'b0;
            emergency_reg <= 1'b0;
            req_valid <= 1'b0;
        end else begin
            req_reg <= req;
            emergency_reg <= emergency;
            req_valid <= |req || emergency;
        end
    end
    
    // 正常仲裁逻辑
    assign normal_grant = req_reg & -req_reg;
    
    // 紧急仲裁逻辑
    assign final_grant = emergency_reg ? 4'b1000 : normal_grant;
    
    // 输出寄存器级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 4'b0;
            ack <= 1'b0;
        end else begin
            grant <= final_grant;
            ack <= req_valid;
        end
    end

endmodule