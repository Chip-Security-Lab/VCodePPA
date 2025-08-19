//SystemVerilog
module AXIStreamBridge #(
    parameter TDATA_W = 32
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire [TDATA_W-1:0]  tdata,
    input  wire                tvalid,
    input  wire                tlast,
    output wire                tready
);
    // 状态定义
    localparam IDLE      = 2'b00,
               TRANSFER  = 2'b01;
    
    // 内部寄存器
    reg [1:0]            curr_state;
    reg [1:0]            next_state;
    reg                  tready_reg;
    reg [TDATA_W-1:0]    tdata_reg;
    reg                  tlast_reg;
    
    // 状态转移逻辑 - 增加可预测性
    always @(*) begin
        next_state = curr_state;
        
        case(curr_state)
            IDLE: begin
                if (tvalid)
                    next_state = TRANSFER;
            end
            
            TRANSFER: begin
                if (tlast_reg)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            curr_state <= IDLE;
        else
            curr_state <= next_state;
    end
    
    // 数据通路寄存器 - 减少逻辑深度
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tdata_reg  <= {TDATA_W{1'b0}};
            tlast_reg  <= 1'b0;
        end
        else if (tvalid && tready_reg) begin
            tdata_reg  <= tdata;
            tlast_reg  <= tlast;
        end
    end
    
    // 控制信号生成 - 提高时序裕度
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tready_reg <= 1'b0;
        end
        else begin
            case (next_state)
                IDLE:     tready_reg <= 1'b0;
                TRANSFER: tready_reg <= (tlast_reg) ? 1'b0 : 1'b1;
                default:  tready_reg <= 1'b0;
            endcase
        end
    end
    
    // 输出赋值
    assign tready = tready_reg;
    
endmodule