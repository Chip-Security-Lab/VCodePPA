module subtractor_task (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 低电平复位信号
    input wire [7:0] tdata_a, // AXI-Stream 被减数数据
    input wire tvalid_a,      // AXI-Stream 被减数有效信号
    output reg tready_a,      // AXI-Stream 被减数就绪信号
    input wire [7:0] tdata_b, // AXI-Stream 减数数据
    input wire tvalid_b,      // AXI-Stream 减数有效信号
    output reg tready_b,      // AXI-Stream 减数就绪信号
    output reg [7:0] tdata_res, // AXI-Stream 结果数据
    output reg tvalid_res,    // AXI-Stream 结果有效信号
    input wire tready_res     // AXI-Stream 结果就绪信号
);

reg [7:0] a_reg;             // 被减数寄存器
reg [7:0] b_reg;             // 减数寄存器
reg [7:0] b_complement;      // 减数的补码
reg [7:0] temp_result;       // 临时结果
reg data_valid;              // 数据有效标志

task perform_sub;
    input [7:0] x, y;
    output reg [7:0] result;
    begin
        b_complement = ~y + 1'b1;
        temp_result = x + b_complement;
        result = temp_result[7:0];
    end
endtask

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tready_a <= 1'b1;
        tready_b <= 1'b1;
        tvalid_res <= 1'b0;
        data_valid <= 1'b0;
    end else begin
        if (tvalid_a && tready_a) begin
            a_reg <= tdata_a;
            tready_a <= 1'b0;
        end
        
        if (tvalid_b && tready_b) begin
            b_reg <= tdata_b;
            tready_b <= 1'b0;
        end
        
        if (!tready_a && !tready_b) begin
            data_valid <= 1'b1;
        end
        
        if (data_valid && tready_res) begin
            perform_sub(a_reg, b_reg, tdata_res);
            tvalid_res <= 1'b1;
            tready_a <= 1'b1;
            tready_b <= 1'b1;
            data_valid <= 1'b0;
        end else if (tvalid_res && tready_res) begin
            tvalid_res <= 1'b0;
        end
    end
end

endmodule