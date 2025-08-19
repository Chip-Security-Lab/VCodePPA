//SystemVerilog
//IEEE 1364-2005 Verilog
module hybrid_arbiter #(parameter WIDTH=4) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [1:0] rr_ptr;
    reg [1:0] next_ptr;
    reg [1:0] idx;
    reg found;
    
    // 桶形移位器实现 - 改用参数方式明确定义
    localparam [WIDTH-1:0] BARREL_PATTERN_0 = 4'b0001;
    localparam [WIDTH-1:0] BARREL_PATTERN_1 = 4'b0010;
    
    // 使用寄存器捕获选择信号
    reg [WIDTH-1:0] selected_grant;
    reg [1:0] selected_next_ptr;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            rr_ptr <= 2'b00;
        end 
        else begin
            grant_o <= selected_grant;
            rr_ptr <= selected_next_ptr;
        end
    end
    
    // 显式的多路复用器结构
    always @(*) begin
        // 默认值
        selected_grant = {WIDTH{1'b0}};
        selected_next_ptr = rr_ptr;
        found = 1'b0;
        
        // 第一级多路复用器：基于高优先级请求
        case(1'b1)
            req_i[2]: begin
                selected_grant = 4'b0100;
                found = 1'b1;
            end
            req_i[3]: begin
                selected_grant = 4'b1000;
                found = 1'b1;
            end
            default: begin
                // 继续到轮询部分
                found = 1'b0;
            end
        endcase
        
        // 第二级多路复用器：基于轮询机制
        if (!found) begin
            // 第一轮检查
            idx = rr_ptr;
            if (req_i[idx]) begin
                case(idx)
                    2'd0: selected_grant = BARREL_PATTERN_0;
                    2'd1: selected_grant = BARREL_PATTERN_1;
                    default: selected_grant = {WIDTH{1'b0}};
                endcase
                selected_next_ptr = idx + 1'b1;
                found = 1'b1;
            end
            
            // 第二轮检查（仅当第一轮未找到时进行）
            if (!found) begin
                idx = (rr_ptr + 1'b1) % 2'd2;
                if (req_i[idx]) begin
                    case(idx)
                        2'd0: selected_grant = BARREL_PATTERN_0;
                        2'd1: selected_grant = BARREL_PATTERN_1;
                        default: selected_grant = {WIDTH{1'b0}};
                    endcase
                    selected_next_ptr = idx + 1'b1;
                end
            end
        end
    end
endmodule