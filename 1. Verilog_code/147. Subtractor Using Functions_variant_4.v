module subtractor_pipeline (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 异步复位，低电平有效
    input wire valid_in,     // 输入数据有效信号
    output reg ready_in,     // 输入数据就绪信号
    input wire [7:0] a,      // 被减数
    input wire [7:0] b,      // 减数
    output reg valid_out,    // 输出数据有效信号
    input wire ready_out,    // 输出数据就绪信号
    output reg [7:0] res     // 差
);

// 流水线寄存器定义
reg [7:0] a_reg;            // 被减数寄存器
reg [7:0] b_reg;            // 减数寄存器
reg [7:0] sub_result;       // 减法结果寄存器

// 流水线控制信号
wire [7:0] sub_wire;        // 组合逻辑减法结果
reg [2:0] pipeline_state;   // 流水线状态寄存器

// 状态定义
localparam IDLE = 3'b000;
localparam STAGE1 = 3'b001;
localparam STAGE2 = 3'b010;
localparam STAGE3 = 3'b100;

// 减法运算组合逻辑
assign sub_wire = a_reg - b_reg;

// 流水线状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_reg <= 8'b0;
        b_reg <= 8'b0;
        sub_result <= 8'b0;
        res <= 8'b0;
        valid_out <= 1'b0;
        ready_in <= 1'b1;
        pipeline_state <= IDLE;
    end else begin
        case (pipeline_state)
            IDLE: begin
                if (valid_in && ready_in) begin
                    a_reg <= a;
                    b_reg <= b;
                    pipeline_state <= STAGE1;
                    ready_in <= 1'b0;
                end
            end
            STAGE1: begin
                sub_result <= sub_wire;
                pipeline_state <= STAGE2;
            end
            STAGE2: begin
                if (ready_out) begin
                    res <= sub_result;
                    valid_out <= 1'b1;
                    pipeline_state <= STAGE3;
                end
            end
            STAGE3: begin
                valid_out <= 1'b0;
                ready_in <= 1'b1;
                pipeline_state <= IDLE;
            end
        endcase
    end
end

endmodule