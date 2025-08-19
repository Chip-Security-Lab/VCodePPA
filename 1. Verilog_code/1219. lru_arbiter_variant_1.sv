//SystemVerilog
module lru_arbiter #(parameter WIDTH=4) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [WIDTH-1:0] usage [0:WIDTH-1];
    reg [WIDTH-1:0] req_reg;
    reg [$clog2(WIDTH)-1:0] lru_index;
    integer i;
    
    // 第一阶段：寄存输入请求信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_reg <= {WIDTH{1'b0}};
        end else begin
            req_reg <= req_i;
        end
    end
    
    // 第二阶段：计算LRU索引
    always @(*) begin
        lru_index = 0;
        for (i = 1; i < WIDTH; i = i + 1) begin
            if (req_reg[i] && usage[i] < usage[lru_index]) begin
                lru_index = i;
            end else if (req_reg[i] && !req_reg[lru_index]) begin
                lru_index = i;
            end
        end
    end
    
    // 第三阶段：更新授权输出和使用计数(使用桶形移位器结构)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            for (i = 0; i < WIDTH; i = i + 1) begin
                // 使用桶形移位器初始化
                case (i)
                    0: usage[i] <= 4'b0001;
                    1: usage[i] <= 4'b0010;
                    2: usage[i] <= 4'b0100;
                    3: usage[i] <= 4'b1000;
                    default: usage[i] <= 4'b0001;
                endcase
            end
        end else begin
            // 使用桶形移位器实现grant_o的生成
            case (lru_index)
                0: grant_o <= 4'b0001;
                1: grant_o <= 4'b0010;
                2: grant_o <= 4'b0100;
                3: grant_o <= 4'b1000;
                default: grant_o <= 4'b0000;
            endcase
            
            // 使用桶形移位器结构更新usage
            case (lru_index)
                0: usage[0] <= {1'b1, usage[0][WIDTH-1:1]};
                1: usage[1] <= {1'b1, usage[1][WIDTH-1:1]};
                2: usage[2] <= {1'b1, usage[2][WIDTH-1:1]};
                3: usage[3] <= {1'b1, usage[3][WIDTH-1:1]};
            endcase
        end
    end
endmodule