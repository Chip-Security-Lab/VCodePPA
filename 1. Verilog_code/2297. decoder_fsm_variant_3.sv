//SystemVerilog
module decoder_fsm (
    input clk, rst_n,
    input [3:0] addr,
    input valid_in,           // 输入有效信号
    output reg valid_out,     // 输出有效信号
    output reg [7:0] decoded,
    output reg ready          // 就绪信号，指示流水线可接受新输入
);
    // 流水线阶段定义
    localparam STAGE_VALIDATE = 2'b00;
    localparam STAGE_DECODE = 2'b01;
    localparam STAGE_OUTPUT = 2'b10;
    
    // 优化的流水线寄存器
    reg [3:0] addr_stage1, addr_stage2;
    reg valid_stage1, valid_stage2;
    reg [7:0] decoded_stage1, decoded_stage2;
    
    // 组合逻辑计算部分（向前移动）
    wire addr_valid = (addr < 4'd8);
    wire [7:0] decoded_wire = valid_in ? (addr_valid ? (8'h01 << addr[2:0]) : 8'h00) : 8'h00;
    
    // 流水线阶段1：前向推移寄存器（过了组合逻辑）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
            decoded_stage1 <= 8'h00;
        end else begin
            if (ready) begin
                addr_stage1 <= addr;
                valid_stage1 <= valid_in;
                decoded_stage1 <= decoded_wire; // 直接存储解码后的结果
            end
        end
    end
    
    // 流水线阶段2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
            decoded_stage2 <= 8'h00;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
            decoded_stage2 <= decoded_stage1;
        end
    end
    
    // 流水线阶段3：输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 8'h00;
            valid_out <= 1'b0;
        end else begin
            decoded <= decoded_stage2;
            valid_out <= valid_stage2;
        end
    end
    
    // 流水线控制逻辑
    always @(*) begin
        // 始终准备接收新数据
        ready = 1'b1;
    end
endmodule