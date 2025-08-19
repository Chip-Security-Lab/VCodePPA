//SystemVerilog
module axi_stream_adapter #(parameter DW=32) (
    input  wire clk,
    input  wire resetn,
    input  wire [DW-1:0] tdata,
    input  wire tvalid,
    output wire tready,
    output wire [DW-1:0] rdata,
    output wire rvalid
);
    // 内部信号定义
    wire [7:0] difference_comb;
    reg  tready_reg;
    reg  rvalid_reg;
    reg  [DW-1:0] rdata_reg;
    
    // 定义状态编码
    reg [1:0] state;
    localparam STATE_RESET  = 2'b00;
    localparam STATE_ACTIVE = 2'b01;
    localparam STATE_IDLE   = 2'b10;
    
    // 实例化组合逻辑模块 - 8位减法器
    subtractor_8bit u_subtractor (
        .minuend(tdata[7:0]),
        .subtrahend(tdata[15:8]),
        .difference(difference_comb)
    );
    
    // 输出信号连接
    assign tready = tready_reg;
    assign rvalid = rvalid_reg;
    assign rdata = rdata_reg;
    
    // 状态机控制逻辑(纯时序逻辑)
    always @(posedge clk) begin
        if (!resetn) begin
            state <= STATE_RESET;
            tready_reg <= 1'b1;
            rvalid_reg <= 1'b0;
            rdata_reg <= {DW{1'b0}};
        end
        else begin
            case (state)
                STATE_RESET: begin
                    state <= STATE_IDLE;
                    tready_reg <= 1'b1;
                    rvalid_reg <= 1'b0;
                end
                
                STATE_IDLE: begin
                    if (tvalid & tready_reg) begin
                        // 将减法结果存储在rdata的低8位
                        rdata_reg <= {tdata[DW-1:8], difference_comb};
                        rvalid_reg <= 1'b1;
                        tready_reg <= 1'b0;
                        state <= STATE_ACTIVE;
                    end
                end
                
                STATE_ACTIVE: begin
                    rvalid_reg <= 1'b0;
                    tready_reg <= 1'b1;
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                    tready_reg <= 1'b1;
                    rvalid_reg <= 1'b0;
                end
            endcase
        end
    end
endmodule

// 纯组合逻辑 - 8位减法器
module subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] difference
);
    // 内部信号
    wire [7:0] not_subtrahend;
    wire [8:0] carry;  // 额外一位用于进位链
    wire [7:0] diff_internal;
    
    // 对减数取反
    assign not_subtrahend = ~subtrahend;
    
    // 初始进位设为1
    assign carry[0] = 1'b1;
    
    // 位级减法实现 (使用generate生成多个全加器)
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_subtractor
            // 位级求和逻辑
            assign diff_internal[i] = minuend[i] ^ not_subtrahend[i] ^ carry[i];
            
            // 计算下一位进位
            assign carry[i+1] = (minuend[i] & not_subtrahend[i]) | 
                                (minuend[i] & carry[i]) | 
                                (not_subtrahend[i] & carry[i]);
        end
    endgenerate
    
    // 连接输出
    assign difference = diff_internal;
endmodule